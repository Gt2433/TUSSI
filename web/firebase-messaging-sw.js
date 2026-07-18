importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

// Initialize Firebase compat inside Service Worker
firebase.initializeApp({
  apiKey: "AIzaSyCtEPgAIoEY6rZpzYBAurutr-kCobJaaBI",
  messagingSenderId: "368377187521",
  projectId: "fantex",
  storageBucket: "fantex.firebasestorage.app",
});

const messaging = firebase.messaging();

// Handle background notifications in PWA
messaging.onBackgroundMessage((payload) => {
  console.log("Received background messaging payload: ", payload);
  
  const notificationTitle = payload.notification?.title || "طلبية جديدة 📥";
  const notificationOptions = {
    body: payload.notification?.body || "وصلتك طلبية جديدة",
    icon: "/icons/Icon-192.png",
    data: payload.data,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
