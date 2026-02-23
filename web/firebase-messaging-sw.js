importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBY9cBheiZJ20h1TslV4pVi4eUiwsxS3_o",
  authDomain: "techlead-57814.firebaseapp.com",
  projectId: "techlead-57814",
  storageBucket: "techlead-57814.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "1:567120658052:android:7234e24263faed6c4accd1"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Background Message:', payload);
});