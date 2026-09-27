const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const twilio = require("twilio");

admin.initializeApp();
const client = twilio(process.env.TWILIO_SID, process.env.TWILIO_TOKEN);

// Every morning: text every user a vibe + a promo for InstaVibe Plus.
exports.dailyVibe = onSchedule("every day 09:00", async () => {
  const users = await admin.firestore().collection("users").where("dailyTexts", "==", true).get();
  for (const u of users.docs) {
    await client.messages.create({
      from: "+15550001111",
      to: u.data().phone,
      body: "☀️ Today's vibe: go outside. Upgrade to InstaVibe Plus for 50% off → instavibe.app/plus",
    });
  }
});
