---
name: grill-with-docs-and-lavish
description: The grill-with-docs interview (a relentless interview that also creates the ADRs and glossary), followed by a Lavish Editor review where the user annotates the agreed outcome before anything is built.
disable-model-invocation: true
---

This is `grill-with-docs` followed by `lavish`: grill the user, keep the docs current as you go, then put the outcome in front of the user as a page they can annotate.

## 1. Grill

Load the `grilling` and `domain-modeling` skills and run the interview exactly as they describe. Do not shorten it to reach the review sooner: the page is only worth reading once the frontier is empty.

## 2. Review the outcome in Lavish

When the frontier is empty, `grilling` asks the user to confirm a shared understanding. Run this review in place of asking for that confirmation in chat. A page the user can read end to end and mark up catches misunderstandings that a chat summary hides.

### Build the page

1. Load the `lavish` skill, then run `npx -y lavish-axi@0.6.0 --help` and `npx -y lavish-axi@0.6.0 playbook plan`. The CLI is the source of truth for its commands, the review loop, where the artifact lives, and visual design. This skill decides what the page contains and what it is for.
2. Write one HTML artifact that summarises the outcome:
   - the problem and the goal, in the user's words;
   - what will be built, as behaviour the user will see, or the decision reached when nothing user-visible is built;
   - what is explicitly out of scope;
   - every decision settled in the interview with the chosen answer, marking the ones where the user accepted your recommendation without discussion, since those are the likeliest to be wrong;
   - the glossary terms and ADRs added or changed in this session;
   - the risks the user should know about.

   Use the project glossary's vocabulary. Leave out file paths and code, which go stale.
3. The page carries no open questions. An assumption you notice while writing it is an unsettled decision: take it back to the user as a `grilling` question before you open the page.
4. The page is for marking up, not for filling in. Keep annotation on, and do not turn the decisions into radio buttons or forms, even where the `input` playbook would. The one control is an Approve button, built the way the `input` playbook builds a button that queues a prompt, so that approval arrives as feedback you can recognise.
5. If the repository does not ignore the directory the artifact lives in, add it to `.gitignore` and say so.

### Run the review loop

6. Open the page with `npx -y lavish-axi@0.6.0 <html-file>` and wait for feedback the way `--help` describes. The wait lasts as long as the user takes to read, so give the poll the longest timeout your harness allows, and run it again if it times out.
7. Sort each annotation by what it asks for:
   - a different decision: reopen it. A changed decision can change the ones that hang off it, so recompute the frontier and ask any new questions as a further `grilling` round in chat. The user is looking at the browser, so first post a Lavish reply saying the questions are waiting in chat;
   - different wording or layout: fix the page;
   - a correction to a term or an ADR: fix it with `domain-modeling`.

   Then bring the glossary and ADRs in line with the changed decisions, regenerate the page, and wait for feedback again.
8. If the user ends the session or the browser disconnects before approving, apply the feedback you received, then ask in chat whether to reopen the page. Do not reopen it uninvited.
9. The review is done when the user approves, with the Approve button or in words. A session that ends without approval is not approval.

Approval of the page is the confirmation `grilling` requires. It is not a request to build: unless the user asked for that when they started, what happens next (`/to-spec`, `/implement`) is their call.
