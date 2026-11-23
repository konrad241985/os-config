---
name: grill-with-lavish
description: The grill-with-docs interview, followed by a visual review of the agreed outcome in Lavish Editor, where the user annotates what they do not like before anything is built.
disable-model-invocation: true
---

Run the same session as `grill-with-docs`, then put the outcome in front of the user as a page they can annotate.

## 1. Grill

Load the `grilling` and `domain-modeling` skills and run the interview exactly as they describe. Both come from `mattpocock/skills`. If either is unavailable, stop and tell the user to install them.

## 2. Review the outcome in Lavish

When the frontier is empty, `grilling` asks the user to confirm a shared understanding. Run this review in place of asking for that confirmation in chat. A page the user can read end to end and mark up catches misunderstandings that a chat summary hides.

1. Run `npx -y lavish-axi --help` and `npx -y lavish-axi playbook plan`, plus any other playbook the content calls for. The CLI is the source of truth for the review loop, the artifact location, and the design. Follow it over anything written here.
2. Write one HTML artifact that summarises what will be built:
   - the problem and the goal, in the user's words;
   - what will be built, as behaviour the user will see;
   - what is explicitly out of scope;
   - every decision settled in the interview with the chosen answer, marking the ones where the user accepted your recommendation without discussion, since those are the likeliest to be wrong;
   - the glossary terms and ADRs added or changed in this session;
   - the assumptions and risks still open.

   Use the `GLOSSARY.md` vocabulary. Leave out file paths and code, which go stale.
3. Open it with `npx -y lavish-axi <html-file>` and wait for the user's feedback the way `--help` describes.
4. Treat each annotation as reopening the decision it points at. A changed decision can change the ones that hang off it, so recompute the frontier and ask any new questions as a further `grilling` round. Update `GLOSSARY.md` and the ADRs to match, regenerate the artifact, and wait for feedback again.
5. The review is done when the user says the page is right. If they end the session without saying so, ask in chat.

Approval of the page is the confirmation `grilling` requires. Stop there: what happens next (`/to-spec`, `/implement`) is the user's call.
