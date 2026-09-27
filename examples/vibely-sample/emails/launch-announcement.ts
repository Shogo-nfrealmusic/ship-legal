export function launchAnnouncementEmail({ appUrl }: { appUrl: string }) {
  return {
    subject: "Vibely is live — claim your username 🎉",
    html: `
      <div style="font-family: Inter, Arial, sans-serif; max-width: 520px; margin: 0 auto;">
        <h1 style="font-size: 28px;">We're live!</h1>
        <p>You joined the Vibely waitlist, and today the doors are open.</p>
        <p>Claim your username before someone else does, and get <b>50% off Vibely Pro</b>
        for your first 3 months with code <b>EARLYVIBE</b>.</p>
        <p><a href="${appUrl}/signup" style="background:#7c3aed;color:#fff;padding:12px 20px;border-radius:10px;text-decoration:none;">Claim my username</a></p>
        <p>See you inside,<br/>The Vibely team</p>
      </div>
    `,
  };
}
