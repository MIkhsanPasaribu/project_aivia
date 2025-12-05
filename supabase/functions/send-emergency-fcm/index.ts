/**
 * Supabase Edge Function: send-emergency-fcm
 *
 * Purpose: Automatically send Firebase Cloud Messaging (FCM) notifications
 *          for emergency alerts and pending notifications.
 *
 * Trigger:
 * - Scheduled via pg_cron (every 1 minute)
 * - Manual invocation via HTTP POST
 *
 * Process Flow:
 * 1. Query pending notifications from database (limit 50)
 * 2. Get FCM tokens for each recipient
 * 3. Send notification via Firebase HTTP v1 API
 * 4. Log delivery status to notification_delivery_logs
 * 5. Update notification status to 'sent' or 'failed'
 *
 * Cost: $0/month (Supabase FREE tier: 500K invocations/month)
 *
 * @author AIVIA Development Team
 * @date 2025-11-19
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// ============================================================================
// TYPES & INTERFACES
// ============================================================================

interface PendingNotification {
  id: string;
  recipient_user_id: string;
  notification_type: string;
  title: string;
  body: string;
  data: Record<string, any> | null;
  scheduled_at: string;
}

interface FCMToken {
  token: string;
  device_type: string;
}

interface DeliveryResult {
  notification_id: string;
  recipient_user_id: string;
  tokens_sent: number;
  tokens_failed: number;
  status: "success" | "partial" | "failed";
  error?: string;
}

interface ServiceAccount {
  type: string;
  project_id: string;
  private_key_id: string;
  private_key: string;
  client_email: string;
  client_id: string;
  auth_uri: string;
  token_uri: string;
  auth_provider_x509_cert_url: string;
  client_x509_cert_url: string;
}

// ============================================================================
// ENVIRONMENT VARIABLES
// ============================================================================

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SERVICE_ROLE_KEY")!;
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!;

// Validate environment variables
if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  throw new Error("Missing required Supabase environment variables");
}

if (!FIREBASE_SERVICE_ACCOUNT) {
  throw new Error("Missing FIREBASE_SERVICE_ACCOUNT environment variable");
}

// Parse service account
const serviceAccount: ServiceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT);
const FIREBASE_PROJECT_ID = serviceAccount.project_id;

// ============================================================================
// FIREBASE OAUTH 2.0 TOKEN GENERATION
// ============================================================================

/**
 * Generate OAuth 2.0 access token using service account
 * This replaces Firebase Admin SDK initialization
 */
async function getAccessToken(): Promise<string> {
  try {
    // Create JWT for Google OAuth 2.0
    const header = {
      alg: "RS256",
      typ: "JWT",
    };

    const now = Math.floor(Date.now() / 1000);
    const expiry = now + 3600; // 1 hour

    const payload = {
      iss: serviceAccount.client_email,
      sub: serviceAccount.client_email,
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: expiry,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
    };

    // Import crypto key
    const privateKey = serviceAccount.private_key;
    const pemHeader = "-----BEGIN PRIVATE KEY-----";
    const pemFooter = "-----END PRIVATE KEY-----";
    const pemContents = privateKey.substring(
      pemHeader.length,
      privateKey.length - pemFooter.length - 1
    );
    const buffer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

    const cryptoKey = await crypto.subtle.importKey(
      "pkcs8",
      buffer,
      {
        name: "RSASSA-PKCS1-v1_5",
        hash: "SHA-256",
      },
      false,
      ["sign"]
    );

    // Create JWT
    const encodedHeader = btoa(JSON.stringify(header))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=/g, "");
    const encodedPayload = btoa(JSON.stringify(payload))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=/g, "");

    const signatureInput = `${encodedHeader}.${encodedPayload}`;
    const signatureBuffer = await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      cryptoKey,
      new TextEncoder().encode(signatureInput)
    );

    const signature = btoa(
      String.fromCharCode(...new Uint8Array(signatureBuffer))
    )
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=/g, "");

    const jwt = `${signatureInput}.${signature}`;

    // Exchange JWT for access token
    const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      }),
    });

    if (!tokenResponse.ok) {
      const error = await tokenResponse.text();
      throw new Error(`Failed to get access token: ${error}`);
    }

    const tokenData = await tokenResponse.json();
    return tokenData.access_token;
  } catch (error) {
    console.error("❌ Error generating access token:", error);
    throw error;
  }
}

// ============================================================================
// FCM SEND FUNCTION
// ============================================================================

/**
 * Send FCM notification using Firebase HTTP v1 API
 */
async function sendFCMNotification(
  token: string,
  title: string,
  body: string,
  data: Record<string, any> | null,
  accessToken: string
): Promise<{ success: boolean; error?: string }> {
  try {
    const url = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;

    const message = {
      message: {
        token: token,
        notification: {
          title: title,
          body: body,
        },
        data: data || {},
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channel_id: "emergency_alerts",
          },
        },
      },
    };

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(message),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error(`❌ FCM send failed for token ${token}:`, error);
      return { success: false, error };
    }

    const result = await response.json();
    console.log(`✅ FCM sent successfully:`, result);
    return { success: true };
  } catch (error) {
    console.error(`❌ Exception sending FCM:`, error);
    return { success: false, error: String(error) };
  }
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req: Request) => {
  try {
    console.log("🔔 Edge Function invoked:", new Date().toISOString());

    // CORS headers
    if (req.method === "OPTIONS") {
      return new Response("ok", {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers":
            "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    // Create Supabase client with service role key
    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    // Get Firebase access token
    console.log("🔑 Getting Firebase access token...");
    const accessToken = await getAccessToken();
    console.log("✅ Access token obtained");

    // ========================================================================
    // STEP 1: Get pending notifications
    // ========================================================================

    console.log("📨 Fetching pending notifications...");

    const { data: notifications, error: notifError } = await supabase.rpc(
      "get_pending_emergency_notifications",
      { batch_size: 50 }
    );

    if (notifError) {
      console.error("❌ Error fetching notifications:", notifError);
      throw notifError;
    }

    if (!notifications || notifications.length === 0) {
      console.log("ℹ️ No pending notifications");
      return new Response(
        JSON.stringify({
          success: true,
          message: "No pending notifications",
          processed: 0,
        }),
        {
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    console.log(`📬 Found ${notifications.length} pending notifications`);

    // ========================================================================
    // STEP 2: Process each notification
    // ========================================================================

    const results: DeliveryResult[] = [];

    for (const notification of notifications) {
      console.log(`\n🔄 Processing notification ${notification.id}...`);

      // Get FCM tokens for recipient
      const { data: tokens, error: tokenError } = await supabase
        .from("fcm_tokens")
        .select("token, device_type")
        .eq("user_id", notification.recipient_user_id)
        .eq("is_active", true);

      if (tokenError) {
        console.error("❌ Error fetching tokens:", tokenError);
        results.push({
          notification_id: notification.id,
          recipient_user_id: notification.recipient_user_id,
          tokens_sent: 0,
          tokens_failed: 0,
          status: "failed",
          error: tokenError.message,
        });
        continue;
      }

      if (!tokens || tokens.length === 0) {
        console.log("⚠️ No FCM tokens found for user");
        results.push({
          notification_id: notification.id,
          recipient_user_id: notification.recipient_user_id,
          tokens_sent: 0,
          tokens_failed: 0,
          status: "failed",
          error: "No FCM tokens found",
        });

        // Update notification status to failed
        await supabase
          .from("pending_notifications")
          .update({ status: "failed" })
          .eq("id", notification.id);

        continue;
      }

      console.log(`📱 Found ${tokens.length} device(s) for user`);

      // ======================================================================
      // STEP 3: Send to all tokens
      // ======================================================================

      let successCount = 0;
      let failureCount = 0;

      for (const tokenData of tokens) {
        const sendResult = await sendFCMNotification(
          tokenData.token,
          notification.title,
          notification.body,
          notification.data,
          accessToken
        );

        if (sendResult.success) {
          successCount++;

          // Log delivery
          await supabase.from("notification_delivery_logs").insert({
            notification_id: notification.id,
            recipient_user_id: notification.recipient_user_id,
            fcm_token: tokenData.token,
            status: "sent",
            sent_at: new Date().toISOString(),
          });
        } else {
          failureCount++;

          // Log failure
          await supabase.from("notification_delivery_logs").insert({
            notification_id: notification.id,
            recipient_user_id: notification.recipient_user_id,
            fcm_token: tokenData.token,
            status: "failed",
            error_message: sendResult.error,
            sent_at: new Date().toISOString(),
          });

          // Check if token is invalid (should deactivate)
          if (
            sendResult.error?.includes("invalid") ||
            sendResult.error?.includes("not found") ||
            sendResult.error?.includes("Requested entity was not found")
          ) {
            console.log(`🗑️ Deactivating invalid token: ${tokenData.token}`);
            await supabase
              .from("fcm_tokens")
              .update({ is_active: false })
              .eq("token", tokenData.token);
          }
        }
      }

      // ======================================================================
      // STEP 4: Update notification status
      // ======================================================================

      const finalStatus =
        successCount > 0 && failureCount === 0
          ? "sent"
          : successCount > 0
          ? "partial"
          : "failed";

      await supabase
        .from("pending_notifications")
        .update({ status: finalStatus })
        .eq("id", notification.id);

      results.push({
        notification_id: notification.id,
        recipient_user_id: notification.recipient_user_id,
        tokens_sent: successCount,
        tokens_failed: failureCount,
        status: finalStatus as "success" | "partial" | "failed",
      });

      console.log(`✅ Notification ${notification.id}: ${finalStatus}`);
      console.log(`   Sent: ${successCount}, Failed: ${failureCount}`);
    }

    // ========================================================================
    // FINAL RESPONSE
    // ========================================================================

    const summary = {
      success: true,
      processed: notifications.length,
      results: results,
      timestamp: new Date().toISOString(),
    };

    console.log("\n📊 Summary:");
    console.log(`   Total processed: ${notifications.length}`);
    console.log(
      `   Successful: ${results.filter((r) => r.status === "sent").length}`
    );
    console.log(
      `   Partial: ${results.filter((r) => r.status === "partial").length}`
    );
    console.log(
      `   Failed: ${results.filter((r) => r.status === "failed").length}`
    );

    return new Response(JSON.stringify(summary), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("❌ Edge Function error:", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: String(error),
        timestamp: new Date().toISOString(),
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
