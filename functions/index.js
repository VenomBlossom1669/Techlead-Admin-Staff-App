    const functions = require("firebase-functions");
    const admin = require("firebase-admin");
    const { onSchedule } = require("firebase-functions/v2/scheduler");
    const { log, warn, error } = require("firebase-functions/logger");
    const { onCall } = require("firebase-functions/v2/https");

    admin.initializeApp();

    // 🔹 Delete user from Firebase Authentication
   exports.deleteUserAuth = onCall(async (request) => {
     try {
       const uid = request.data.uid;

       if (!uid) throw new Error("UID is required!");

       await admin.auth().deleteUser(uid);
       return { success: true };
     } catch (err) {
       console.error("❌ deleteUserAuth error:", err);
       return { success: false, error: err.message };
     }
   });
    // 🔹 Auto Checkout Function
    exports.autoCheckOut = onSchedule(
      {
        schedule: "every day 18:28", // 18:28 PM UTC = 23:58 PM IST
        timeZone: "UTC",
      },
      async () => {
        const db = admin.firestore();

        try {
          const now = new Date(
            new Date().toLocaleString("en-US", { timeZone: "Asia/Kolkata" })
          );
          log(`⏰ Auto checkout started at (IST): ${now.toISOString()}`);

          const snapshot = await db
            .collection("Attendance")
            .where("checkIn", "!=", null)
            .get();

          if (snapshot.empty) {
            log("📭 No attendance records found with checkIn.");
            return null;
          }

          const updates = [];

          snapshot.docs
            .filter((doc) => {
              const dbCheckOut = doc.data().checkOut;
              return !dbCheckOut || dbCheckOut === "";
            })
            .forEach((doc) => {
              const data = doc.data();
              const docId = doc.id;
              const employeeName = data.employeeName;
              const userId = data.userId;

              const checkInStr = data.checkIn;
              const dateStr = data.date;

              if (!checkInStr || !dateStr) {
                warn(
                  `⚠️ Skipping doc [${docId}] with userId [${userId}] due to missing checkIn or date.`
                );
                return;
              }

              const [day, month, year] = dateStr.split("/").map(Number);
              const [hour, minute] = checkInStr.split(":").map(Number);
              const checkInTime = new Date(year, month - 1, day, hour, minute);
              const nineHoursLater = new Date(checkInTime.getTime() + 9 * 60 * 60 * 1000);

              if (now >= nineHoursLater) {
                const checkOutStr = nineHoursLater.toTimeString().slice(0, 5);
                const durationMinutes = (nineHoursLater - checkInTime) / 60000;
                const hours = Math.floor(durationMinutes / 60);
                const minutes = Math.floor(durationMinutes % 60);
                const status = hours >= 8 ? "Full Day" : "Half Day";

                updates.push(
                  doc.ref.update({
                    checkOut: checkOutStr,
                    status,
                    record: `${hours} hours, ${minutes} minutes`,
                    autoCheckedOut: true,
                    checkOutLocation: data.checkInLocation,
                  })
                );

                log(
                  `✅ Auto checkout prepared for userId [${userId}] with employeeName [${employeeName}].`
                );
              } else {
                log(`⏳ Skipping doc [${docId}] - not yet 9 hours since check-in.`);
              }
            });

          await Promise.all(updates);
          log(`🎉 Auto checked out ${updates.length} user(s) successfully.`);
          return null;
        } catch (e) {
          error("❌ Error during auto checkout function:", e);
          return null;
        }
      }
    );
