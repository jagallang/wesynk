importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCacTCkp8qO2pf1zFHK1k9GRddHXfYP9QU",
  appId: "1:242440576982:web:945cd5cd79cf976917ce77",
  messagingSenderId: "242440576982",
  projectId: "wesynk-app",
  authDomain: "wesynk-app.firebaseapp.com",
  storageBucket: "wesynk-app.firebasestorage.app",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  const { title, body } = message.notification || {};
  if (title) {
    self.registration.showNotification(title, {
      body: body || "",
      icon: "/icons/Icon-192.png",
    });
  }
});
