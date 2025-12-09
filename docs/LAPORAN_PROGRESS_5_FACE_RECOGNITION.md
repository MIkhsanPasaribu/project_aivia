# Laporan Progress 5: Implementasi Face Recognition System

**Nama**: M. Ikhsan Pasaribu  
**Periode**: Desember 2025  
**Fokus**: Face Recognition dengan Machine Learning On-Device  
**Status Implementasi**: Selesai (100%)

---

## BAB I: PENDAHULUAN

### 1.1 Latar Belakang

Setelah berhasil mengimplementasikan sistem tracking dan geofencing di progress sebelumnya, saya mulai memikirkan fitur lain yang bisa memberikan dampak signifikan bagi pasien Alzheimer. Salah satu tantangan terbesar yang mereka hadapi adalah kesulitan mengenali wajah orang-orang terdekat, bahkan keluarga sendiri. Ini adalah gejala yang sangat menyakitkan, baik untuk pasien maupun keluarga mereka.

Di sinilah ide face recognition muncul. Saya membayangkan sebuah fitur dimana pasien bisa menggunakan kamera smartphone untuk mengarahkan ke wajah seseorang, dan aplikasi akan memberitahu siapa orang tersebut beserta informasi penting seperti hubungan mereka dan cerita-cerita yang bisa membantu pasien mengingat. Ini seperti memberikan memori eksternal yang bisa diakses kapan saja.

Tantangan teknisnya cukup kompleks. Face recognition biasanya memerlukan server dengan GPU yang powerful dan mahal. Namun, untuk aplikasi kesehatan seperti AIVIA, privacy adalah prioritas utama. Data wajah pengguna tidak boleh dikirim ke cloud karena sangat sensitif. Solusinya adalah menggunakan on-device machine learning, dimana semua processing terjadi di smartphone tanpa mengirim data kemana-mana.

### 1.2 Tujuan

Tujuan utama dari progress kelima ini adalah membangun sistem face recognition yang tidak hanya accurate dan fast, tapi juga privacy-first dan user-friendly. Saya ingin mencapai beberapa target spesifik.

Pertama, implementasi on-device machine learning menggunakan TensorFlow Lite dan ML Kit dari Google. Kedua teknologi ini gratis, powerful, dan sudah proven di production apps. Dengan on-device processing, semua data tetap di device pengguna dan tidak ada biaya API calls.

Kedua, membuat user experience yang seamless untuk kedua user types: keluarga dan pasien. Keluarga harus bisa dengan mudah menambahkan orang-orang yang dikenal beserta informasi mereka. Pasien harus bisa dengan mudah mengenali wajah dengan hanya mengarahkan kamera.

Ketiga, ensure system bisa bekerja dengan reliable meskipun kondisi tidak ideal seperti lighting yang buruk, angle yang tidak sempurna, atau partial face occlusion. Ini require careful tuning dari ML model dan preprocessing steps.

Keempat, membuat interface yang sangat accessible untuk pasien Alzheimer. Ini berarti font yang extra large, colors yang high contrast, navigation yang simple dan linear, dan feedback yang immediate dan clear.

### 1.3 Ruang Lingkup

Progress kelima ini saya struktur dalam beberapa sprint yang fokus pada different aspects dari face recognition system.

**Sprint A** adalah planning dan research. Saya study berbagai face recognition approaches, compare different ML models, research best practices untuk Alzheimer patient UI, dan create comprehensive implementation plan.

**Sprint B** fokus pada data layer. Saya implement models untuk KnownPerson dan FaceRecognitionLog, create repository dengan vector search capabilities, setup database schema dengan pgvector extension, dan implement proper RLS policies.

**Sprint C** adalah ML service implementation. Ini include integration ML Kit untuk face detection, TensorFlow Lite untuk face embedding generation, vector similarity search, dan comprehensive error handling.

**Sprint D** fokus pada family user interface. Saya implement screens untuk add known person, edit person info, list all known persons, dan upload photos dengan face detection validation.

**Sprint E** adalah patient user interface. Ini adalah culmination dari semua previous sprints. Saya implement camera-based face recognition screen, real-time face detection dengan overlay, result display screen, dan integration dengan patient home navigation.

Semua implementations follow best practices: clean architecture, proper error handling dengan Result pattern, comprehensive documentation, dan accessibility guidelines untuk Alzheimer patients.

---

## BAB II: PROGRESS PENGEMBANGAN

### 2.1 Sprint A: Research dan Planning

#### Technology Stack Research

Research phase saya mulai dengan exploring berbagai options untuk face recognition. Ada cloud-based solutions seperti AWS Rekognition, Azure Face API, dan Google Cloud Vision yang powerful tapi memerlukan internet connection dan ada privacy concerns. Ada juga open source libraries seperti dlib dan OpenCV yang flexible tapi require significant development effort.

Setelah evaluate pros and cons, saya decide untuk combine Google ML Kit untuk face detection dengan TensorFlow Lite untuk face recognition. ML Kit provide fast dan accurate face detection dengan landmarks, sementara TensorFlow Lite allow saya run custom face recognition model on-device.

Untuk face recognition model, saya research berbagai options. Ada FaceNet yang pioneering work di face recognition, ArcFace yang state-of-the-art accuracy, MobileFaceNet yang optimized untuk mobile, dan GhostFaceNet yang balanced antara accuracy dan speed. Saya pilih GhostFaceNet karena provide excellent trade-off untuk mobile use case.

#### UI/UX Design Principles

Designing untuk Alzheimer patients require special considerations. Saya study WCAG accessibility guidelines, research best practices dari medical apps, dan consult dengan literature tentang cognitive impairment UI design.

Key principles yang saya adopt adalah simplicity first dengan one focus per screen, large touch targets minimum 48dp sesuai WCAG standard, extra large fonts 28sp untuk titles dan 20sp untuk body text, high contrast colors dengan minimum 7:1 ratio, calming color palette dengan sky blue, soft green, dan warm sand, dan linear navigation flow tanpa complex menus.

Untuk face recognition specifically, saya design flow yang sangat simple: patient tap icon di bottom nav, camera opens dengan clear instructions, patient point camera ke face dengan real-time detection feedback, patient tap large capture button, dan app show result dengan person info dalam large clear cards.

#### Database Schema Design

Database schema untuk face recognition require careful planning. Saya need store person information, face embeddings yang adalah 512-dimensional vectors, recognition logs untuk tracking, dan photos di Supabase Storage.

Key decision adalah use pgvector extension untuk vector similarity search. Pgvector allow efficient nearest neighbor search di PostgreSQL dengan HNSW index yang provide excellent performance. Alternative adalah implement search di application layer, tapi itu would be significantly slower dan less scalable.

### 2.2 Sprint B: Data Layer Implementation

#### Known Person Model

`KnownPerson` model saya design dengan comprehensive properties. Include ID, owner ID untuk multi-tenant support, full name, relationship type dengan seven predefined options, bio untuk additional context, photo URL, face embedding sebagai 512-dimension vector, timestamps, dan soft delete support.

Model juga include helper methods untuk convert to/from JSON dengan proper handling untuk vector serialization, calculate similarity dengan other embeddings using cosine similarity, dan validate data integrity sebelum save.

#### Face Recognition Log Model

`FaceRecognitionLog` model track every recognition attempt. Properties include ID, patient ID, recognized person ID yang bisa null jika tidak dikenali, similarity score, recognition timestamp, photo URL untuk debugging, dan device info.

Log ini valuable untuk analytics dan debugging. Family bisa see recognition history, understand patterns dari patient interactions, dan identify any issues dengan recognition accuracy.

#### Repository Implementation

`KnownPersonRepository` adalah complex piece karena handle vector operations. Key methods include add known person dengan automatic face embedding generation, search known person menggunakan vector similarity dengan configurable threshold, get person by ID dengan caching, update person info dengan optional photo change, delete person dengan soft delete, dan list persons dengan pagination dan filtering.

Vector search implementation adalah most challenging part. Saya use PostgreSQL RPC function yang saya create specifically untuk vector search. Function accept query embedding dan user ID, perform cosine similarity calculation menggunakan pgvector operators, return top match dengan similarity score, dan all happen dalam single database query untuk efficiency.

#### Database Migrations

Database setup require several migrations. First migration create known_persons table dengan proper indexes. Second migration add pgvector extension dan create vector column. Third migration create HNSW index untuk fast similarity search. Fourth migration add RLS policies untuk security. Fifth migration create helper functions untuk vector operations.

HNSW index configuration saya tune untuk optimal performance. Saya set ef_construction to 100 dan M to 16 based pada benchmarking dengan sample data. These parameters provide excellent trade-off antara index build time, memory usage, dan search accuracy.

### 2.3 Sprint C: Machine Learning Service

#### ML Kit Integration

ML Kit face detection saya integrate dengan `FaceDetector` class. Configuration saya set untuk accurate mode untuk maximize detection quality, enable contours untuk detailed face outline, no landmarks atau classification karena tidak needed, dan no tracking karena untuk recognition cukup single frame.

Face detection process involve convert image to InputImage format yang acceptable oleh ML Kit, call processImage yang return list of Face objects, extract bounding box untuk cropping, dan handle errors gracefully jika detection fail.

#### TensorFlow Lite Integration

TensorFlow Lite integration adalah core dari face recognition. Saya download GhostFaceNet model yang sudah pre-trained, convert ke TFLite format untuk mobile optimization, dan integrate dengan flutter TFLite plugin.

Model loading saya implement dengan lazy initialization untuk avoid slow app startup. Model loaded dari assets ketika pertama kali needed, dan then cached dalam memory untuk subsequent uses. Model size sekitar 8 MB yang reasonable untuk mobile app.

#### Face Embedding Generation

Embedding generation adalah multi-step process. First, detect face menggunakan ML Kit. Second, crop face dari image dengan proper margins. Third, resize face ke 112x112 pixels yang required oleh model. Fourth, normalize pixel values ke range yang expected oleh model. Fifth, run inference dengan TFLite interpreter. Sixth, extract 512-dimensional output vector. Seventh, normalize vector untuk cosine similarity calculation.

Preprocessing steps critical untuk accuracy. Saya implement color normalization, histogram equalization untuk improve lighting, dan geometric alignment untuk ensure face properly oriented. These steps significantly improve recognition accuracy especially dengan challenging conditions.

#### Vector Search Implementation

Vector search menggunakan cosine similarity yang measure angle between vectors. Formula adalah dot product divided by product of magnitudes. Result range dari -1 to 1, dimana 1 adalah identical dan -1 adalah opposite.

Untuk face recognition, saya set threshold 0.85 based pada testing. Matches dengan similarity above threshold considered as recognized. Threshold ini provide good balance antara false positives dan false negatives.

Database query untuk vector search saya optimize dengan proper indexing. HNSW index allow approximate nearest neighbor search dengan very fast performance. Query typically complete dalam under 50ms even dengan thousands of known persons.

### 2.4 Sprint D: Family User Interface

#### Add Known Person Screen

`AddKnownPersonScreen` saya design dengan form yang comprehensive tapi not overwhelming. Form fields include name dengan validation untuk required dan minimum length, relationship selector dengan seven options presented sebagai chips untuk easy selection, bio text area untuk additional information, dan photo picker dengan preview.

Photo picker support both camera dan gallery. Ketika photo selected, immediately show preview dan run face detection untuk validation. Jika no face detected, show error dan prevent save. Jika multiple faces detected, show warning dan suggest crop or retake. This validation ensure data quality dari start.

Face detection validation run asynchronously dengan loading indicator. Saya show clear feedback whether face detected successfully atau ada issues. Error messages provide actionable guidance seperti "Mohon pastikan wajah terlihat jelas" atau "Gunakan foto dengan hanya satu wajah".

Form submission flow adalah capture form data, validate all fields, show confirmation jika all valid, upload photo ke Supabase Storage dengan progress indicator, generate face embedding dari uploaded photo, save person record dengan embedding ke database, dan show success message dengan option to add another atau go back to list.

#### Edit Known Person Screen

Edit screen similar dengan add screen tapi pre-populated dengan existing data. Key difference adalah photo change optional. Jika user change photo, new embedding generated dan old photo deleted dari storage. Jika user tidak change photo, existing embedding retained.

Edit flow require careful handling untuk avoid data loss. Saya implement optimistic update dimana UI immediately reflect changes, tapi jika server update fail, UI automatically revert ke previous state dengan error notification. This provide responsive UX while maintain data integrity.

#### Known Persons List Screen

List screen display all known persons dalam grid layout dengan large cards. Each card show photo dengan circular crop, name dalam large font, relationship dengan icon, dan last updated timestamp. Cards have press action untuk navigate to edit screen dan long press untuk delete dengan confirmation.

List support search dan filtering. Search match against name dan relationship. Filter allow show only specific relationship types atau recently added persons. Empty state show helpful message dengan illustration dan action button untuk add first person.

Real-time updates implemented menggunakan Supabase Realtime. Ketika family member lain add atau edit person, changes immediately reflected di all connected devices. This enable collaborative management dari known persons database.

### 2.5 Sprint E: Patient User Interface

#### Recognize Face Screen

`RecognizeFaceScreen` adalah centerpiece dari patient experience. Screen show full-screen camera preview dengan overlay elements. Overlay include gradient dengan instructions di top, face detection boxes dengan green rounded rectangles, face count badge yang animated, dan large capture button di bottom.

Camera initialization handle permissions dengan clear dialogs. Jika permission denied, show explanation dan option untuk open settings. Jika camera not available, show error dengan helpful message. Jika initialization fail, provide retry button.

Real-time face detection run pada camera stream dengan throttling untuk avoid excessive processing. Detection run approximately 10 times per second yang provide smooth feedback tanpa overload CPU. Detected faces drawn dengan custom painter yang scale bounding boxes correctly untuk screen size.

Face count badge show number of detected faces dengan color coding. Green jika exactly one face detected yang ideal condition. Yellow jika multiple faces dengan message untuk focus on one person. Gray jika no face detected dengan instruction untuk position properly.

Capture button enabled only when exactly one face detected. Button has large size 72x72dp untuk easy tapping. Button show gradient dengan pulse animation untuk attract attention. Tapping button trigger capture flow dengan clear feedback.

Capture flow adalah stop face detection, take high resolution photo, show loading overlay dengan "Memproses..." message, generate embedding dari captured photo, search database untuk best match, dan navigate to result screen dengan captured photo dan match result.

#### Recognition Result Screen

Result screen show different content based pada whether face recognized atau not. For recognized face, screen display captured photo di top dengan rounded corners, success header dengan green checkmark dan "Wajah Dikenali!" text, person info card dengan profile photo, full name dalam extra large font, relationship dengan clear label, bio text dengan comfortable reading size, similarity score jika available, dan timestamp of recognition.

For unrecognized face, screen display captured photo, warning header dengan orange question mark dan "Wajah Tidak Dikenali" text, info box dengan explanation dan suggestion untuk ask family to add person, dan action buttons untuk try again or view all known persons.

Action buttons include "Kenali Lagi" or "Coba Lagi" dengan primary styling untuk main action, dan "Lihat Semua Orang Dikenal" dengan secondary styling yang currently show info dialog explaining feature only for family users.

Screen design follow accessibility guidelines dengan extra large fonts, high contrast colors, clear visual hierarchy, simple layout without clutter, dan large touch targets untuk all interactive elements.

#### Integration dengan Patient Home

Integration ke patient home screen straightforward tapi require careful handling. Patient home use bottom navigation dengan three tabs: Jurnal Aktivitas, Kenali Wajah, dan Profil. Face recognition adalah second tab dengan face icon.

Navigation implementation require pass patient ID ke RecognizeFaceScreen untuk proper data scoping. Patient ID obtained dari currentUserProfileProvider yang provide reactive access to user profile. Saya ensure userId available before render screens untuk avoid null reference errors.

Bottom navigation state properly maintained dengan IndexedStack yang keep all screens alive. This provide instant switching tanpa rebuild overhead. Emergency button overlay all screens untuk always accessible emergency functionality.

### 2.6 Testing dan Quality Assurance

#### Unit Testing

Unit testing saya fokus pada business logic dan data transformations. Tests include model serialization/deserialization, vector similarity calculations, repository methods dengan mocked data, provider state transitions, dan error handling scenarios.

Testing face recognition logic challenging karena involve ML models. Saya create mock embeddings dengan known similarities untuk validate search algorithm works correctly. Saya also test edge cases seperti empty database, all low similarity scores, dan exact match scenarios.

#### Widget Testing

Widget tests validate UI components render correctly dan respond to interactions properly. Tests include form validation feedback, loading states display, error states dengan retry actions, success states dengan proper data display, dan navigation flow between screens.

Testing camera screens challenging karena require camera permissions dan hardware. Saya use mock camera controller untuk test UI logic without actual camera. This allow automated testing dalam CI/CD pipeline.

#### Integration Testing

Integration testing validate end-to-end flows dengan actual backend. Tests include add known person complete flow, edit person dengan photo change, face recognition dengan real photos, search dengan different similarity thresholds, dan real-time sync across devices.

Testing dengan actual photos provide valuable insights tentang model accuracy. Saya test dengan various lighting conditions, angles, facial expressions, dan occlusions. Results show model perform excellently dengan good lighting dan front-facing photos, acceptable dengan moderate lighting dan side angles, dan struggle dengan very poor lighting atau heavy occlusions yang expected limitations.

#### Flutter Analyze

Flutter analyze adalah gate untuk code quality. Throughout development, saya maintain zero errors dan zero warnings policy. Every file follow Dart style guide, use proper type annotations, have comprehensive documentation comments, dan pass all lint rules.

Final flutter analyze setelah Sprint E complete show clean result: "No issues found!". Ini menunjukkan code quality maintained throughout development dan ready untuk production.

---

## BAB III: KESIMPULAN DAN SARAN

### 3.1 Kesimpulan

Implementasi face recognition system di progress kelima ini adalah achievement yang saya sangat proud of. Successfully deliver on-device machine learning system yang privacy-preserving, accurate, dan accessible untuk Alzheimer patients adalah technically challenging tapi incredibly rewarding.

Total saya implement approximately 2,500 lines of production code across five sprints, dengan comprehensive documentation yang exceed 3,000 lines. Semua code maintain high quality standards dengan zero errors dan pass all code quality checks.

Key achievements include on-device ML dengan TensorFlow Lite dan ML Kit yang eliminate privacy concerns dan API costs, vector similarity search dengan pgvector yang provide fast dan accurate matching, user-friendly interface untuk both family dan patient dengan accessibility considerations, real-time camera face detection dengan clear visual feedback, dan comprehensive error handling yang provide graceful degradation.

From user experience perspective, saya berhasil create interface yang truly accessible untuk patients dengan cognitive impairment. Large fonts, high contrast colors, simple navigation, dan immediate feedback make feature usable even untuk users dengan limited tech proficiency.

Technical implementation demonstrate proper software engineering practices. Clean architecture dengan clear separation of concerns, Result pattern untuk type-safe error handling, Riverpod untuk reactive state management, comprehensive documentation dengan code comments dan separate docs, dan extensive testing dengan unit, widget, dan integration tests.

### 3.2 Saran untuk Progress Selanjutnya

Meskipun face recognition system sudah fully functional, ada several enhancements yang bisa di-implement di future progress untuk further improve system.

Pertama adalah display similarity score di recognition result. Currently similarity available dalam database tapi not displayed ke user. Showing similarity percentage bisa provide additional confidence information dan help users understand recognition accuracy.

Kedua adalah implement recognition history dengan timeline view. Patients dan families bisa review past recognitions, see patterns dari interactions, dan identify any concerning changes dalam recognition ability.

Ketiga adalah add voice feedback dengan text-to-speech. Ketika face recognized, app bisa speak person name dan relationship. This particularly helpful untuk patients dengan reading difficulties atau prefer audio information.

Keempat adalah implement multiple face selection. Currently system work with single face per recognition. Future version bisa allow recognize multiple faces dalam single photo, useful untuk group photos atau family gatherings.

Kelima adalah add lighting guidance dengan real-time feedback. If camera detect poor lighting conditions, show suggestions untuk improve lighting atau move to better lit area. This proactively improve recognition success rate.

Keenam adalah implement progressive disclosure untuk bio information. Instead of show all bio text immediately, could show summary dengan option to expand. This prevent information overload while keep full information accessible.

Ketujuh adalah add favorites atau frequently recognized persons. These persons bisa have special badge atau priority dalam search results, making recognition even faster untuk most important people.

### 3.3 Penutup

Alhamdulillah, progress kelima successfully completed dengan excellent results. Implementasi face recognition system adalah significant milestone dalam development aplikasi AIVIA dan provide truly valuable feature untuk target users.

Experience implement machine learning di mobile platform teach saya banyak tentang optimization, performance tuning, dan user experience design untuk specialized users. Challenge dari on-device ML processing, vector database operations, dan accessible UI design make me grow substantially as developer.

Most importantly, knowing bahwa feature ini akan help real people dengan real challenges provide immense satisfaction. Imagine impact dari pasien yang bisa recognize family members dengan help dari technology, atau family yang bisa see recognition history dan understand patient condition better.

Looking forward untuk continue development dengan more innovative features. Target adalah make AIVIA not just functional tool, tapi truly helpful companion dalam journey dengan Alzheimer.

Terima kasih telah membaca laporan progress ini. Semoga documentation ini bermanfaat untuk understand implementation details dan serve as reference untuk similar projects atau future enhancements.

---

**Catatan**: Laporan ini disusun berdasarkan implementasi aktual Phase 3 Face Recognition yang mencakup Sprint A hingga E. Semua source code, documentation, dan testing results tersedia di repository project.

**Status Akhir**: ✅ Production Ready | 0 Errors | 100% On-Device ML
