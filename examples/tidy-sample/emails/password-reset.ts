// Transactional email: sent only when the user asks to reset their password.
export function passwordResetEmail(link: string) {
  return {
    subject: "Reset your Tidy Notes password",
    html: `<p>Someone asked to reset your password. If it was you, use this link within 30 minutes:</p>
           <p><a href="${link}">Reset password</a></p>
           <p>If it wasn't you, ignore this email.</p>`,
  };
}
