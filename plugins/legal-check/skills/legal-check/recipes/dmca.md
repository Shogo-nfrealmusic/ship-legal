# Recipe: DMCA page for user uploads (17 U.S.C. §512(c))

Goal: keep the DMCA "safe harbor" for content users upload. That needs a designated
agent registered with the U.S. Copyright Office AND the agent's contact details posted
on the site. Code can do the second part only.

1. Page at `/dmca` (or `/copyright`) with:
   - how to send a takedown notice (identify the work, the infringing URL, contact
     details, a good-faith statement, a statement that the notice is accurate and,
     under penalty of perjury, that the sender is authorized to act for the owner,
     and a signature);
   - the designated agent: name, postal address, phone, email — as clearly marked
     placeholders (`TODO(legal-check): must match your Copyright Office registration`);
   - how to send a counter-notice;
   - a repeat-infringer policy (accounts of repeat infringers are terminated in
     appropriate circumstances).
   Mark the page as a draft for lawyer review at the top of the file (code comment),
   not in the visible text.
2. Terms of Service clause: users must own or have rights to what they upload; you may
   remove content on notice; link to /dmca.
3. Link to /dmca from the site footer (next to Privacy and Terms).
4. Optional contact route: a mailto: link to the agent email is enough. Do not build
   a form that stores notices unless the project already has one.

Human TODO (AI cannot do this): register the designated agent at
https://dmca.copyright.gov (fee $6; the registration expires every 3 years and must be
renewed), then copy the exact same details into the /dmca page.
