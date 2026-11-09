# SpeakDaily — App Flow & User Experience Specification

**Document version:** 1.0  
**Product:** SpeakDaily  
**Platform:** Android first, iOS-ready  
**Design:** Light theme  
**Primary interaction:** Real-time AI voice conversation

---

# 1. Application Navigation

Main bottom navigation contains five destinations:

1. Home
2. Practice
3. Learn
4. Progress
5. Profile

The live conversation screen must be presented as a focused full-screen experience rather than an ordinary tab.

```text
                         APP
                          |
                        Splash
                          |
                    Authentication
                          |
                    Onboarding Check
                     /          \
              New User        Returning User
                 |                 |
             Onboarding           Home
                 |                 |
                 +-----------------+
                          |
                    Main Navigation
                          |
        +-----------------+------------------+
        |                 |                  |
       Home             Practice             Learn
        |                 |                  |
     Start Speaking    Categories        Mistake Vault
        |                 |              Vocabulary
     Tutor Selection      |
        |              Scenario
     Preparation          |
        |              Preparation
        +-----------------+
                 |
          Voice Conversation
                 |
           End Conversation
                 |
           Session Analysis
                 |
            Feedback Screen
                 |
          Save Corrections
                 |
          Update Progress
                 |
                Home
```

# 2. Splash Screen

Purpose:
- Display SpeakDaily branding.
- Initialize Firebase.
- Initialize application configuration.
- Check authentication state.
- Load minimum required application settings.

Flow:
- Authenticated and onboarding complete → Home.
- Authenticated but onboarding incomplete → Onboarding.
- Unauthenticated → Welcome.

Handle initialization failures gracefully.

Do not block the user indefinitely if an optional service is unavailable.

# 3. Welcome Screen

Content:
- SpeakDaily logo.
- Headline: Practice English. Speak with confidence.
- Supporting text: Build confidence through daily conversations with your personal AI English coach.
- Continue with Google.
- Continue with Email.
- Explore as Guest, if guest exploration is enabled.

Design:
- Light background.
- Friendly illustration.
- Clear primary CTA.
- Minimal content.

# 4. Authentication

Supported:
- Google authentication.
- Email/password.
- Email verification as appropriate.

After successful authentication:
- Check user profile.
- Check onboarding completion.
- Route accordingly.

Guest exploration must not silently create a permanent account or bypass usage restrictions. If guest mode is implemented, define how account linking and guest data migration work.

# 5. Onboarding Flow

Keep onboarding short, ideally 2–3 minutes.

## Screen 1 — Interface language

Allow users to select the language used by the application interface.

Do not restrict the app to English-only UI.

## Screen 2 — Native language

Ask the learner's primary language.

Use this to personalize explanations and translations.

## Screen 3 — Learning goal

Options:
- Everyday English.
- Career and interviews.
- Business communication.
- Travel and social communication.
- Academic English.
- Speaking confidence.

Allow multiple goals if useful.

## Screen 4 — English level

Options:
- A1 — Beginner.
- A2 — Elementary.
- B1 — Intermediate.
- B2 — Upper intermediate.
- Not sure.

> **Owner decision (2026-11-09):** C1 — Advanced is also offered (A1, A2, B1, B2, C1, Not sure).

Optional placement assessment can be offered later.

Do not claim a formal CEFR assessment from an unvalidated short conversation.

## Screen 5 — Daily learning goal

Options:
- 5 minutes.
- 10 minutes.
- 15 minutes.
- 20 minutes.

> **Owner decision (2026-11-09):** the options are 5, 10 and 15 minutes. 20 minutes was removed.
> Scenario duration estimates use the same 5, 10 and 15 minute values.

This is the learner's motivational goal, not the free usage allowance.

## Screen 6 — Preferred accent

Options:
- American English.
- British English.
- Australian English.
- International English / No preference.

Accents are preferences, not indicators of English correctness.

## Screen 7 — Personalized learning plan

Display:
- Selected goals.
- Selected level.
- Daily practice target.
- Suggested practice categories.
- Recommended tutor.

## Screen 8 — Account and permissions

Request permissions contextually.

Microphone permission should be requested when the learner starts voice practice, with a clear explanation.

Notification permission should be optional and requested at an appropriate moment.

Complete onboarding and save preferences.

# 6. Home Screen

Purpose: make starting a meaningful practice session easy.

Components:

**Greeting**
- Good morning / afternoon / evening.
- Learner display name if available.

**Daily progress**
- Today's speaking minutes.
- Daily learning goal.
- Free allowance remaining, when relevant.
- Progress indicator.

**Primary action**
- Start Speaking.

**Recommended practice**
- Scenario recommendation.
- Suggested tutor.
- Based on previous learning and mistakes.

**Review section**
- Review mistakes.
- Practice vocabulary.

**Progress overview**
- Current streak.
- Weekly speaking time.
- Completed sessions.

Do not display misleading progress or scores.

# 7. Tutor Selection

MVP tutors:

## Emma — Friendly English Coach

Personality:
- Warm.
- Patient.
- Encouraging.
- Suitable for beginner learners.

Recommended for A1–B1.

## Alex — Professional Communication Coach

Personality:
- Professional.
- Structured.
- Helpful.
- Focused on workplace English.

Recommended for A2–C1.

## Sofia — Everyday Conversation Partner

Personality:
- Natural.
- Expressive.
- Friendly.
- Focused on everyday communication.

Recommended for A1–B2.

Each tutor card should display:
- Name.
- Avatar.
- Personality.
- Voice sample, if supported.
- Recommended learner level.
- Suitable practice categories.

Allow the user to select a tutor.

# 8. Practice Discovery

Categories:

**Everyday**
- Introductions.
- Daily routines.
- Hobbies.
- Shopping.
- Food and restaurants.

**Professional**
- Job interviews.
- Office conversations.
- Meetings.
- Presentations.
- Client communication.

**Academic**
- Classroom discussion.
- Study abroad.
- Explaining ideas.
- Academic discussions.

**Travel**
- Airport.
- Hotel check-in.
- Asking for directions.
- Travel problems.

**Social**
- Making friends.
- Networking.
- Small talk.
- Social events.

> **Owner decisions (2026-11-09):** A1 scenarios added to Professional and Academic; B2 Travel
> expanded; about five Premium scenarios; suggested tutors must be compatible (category and level,
> enforced by the backend); scenarios need human review before publishing; American English for
> the initial release. See `doc/reviews/SCENARIO_REVIEW.md` §5.

Each scenario should include:
- Title.
- Description.
- CEFR recommendation.
- Learning objectives.
- Estimated duration.
- Suggested tutor.
- Relevant vocabulary.

# 9. Conversation Preparation

Before starting a session, display:

- Selected tutor.
- Selected scenario.
- Practice objective.
- Recommended duration.
- Available free or premium usage.
- Start conversation button.

Allow the learner to start a free conversation without selecting a scenario, if appropriate.

Explain microphone permission when necessary.

Check:
- Authentication.
- Network connectivity.
- Microphone permission.
- Available usage allowance.
- Session authorization.

Do not establish an AI session before the user explicitly starts.

# 10. Real-Time Voice Conversation Screen

This is the core SpeakDaily experience.

Screen components:

- Tutor avatar.
- Tutor name.
- Connection status.
- Conversation timer.
- Live transcript.
- Listening / speaking indicators.
- Microphone mute/unmute.
- End conversation button.

Conversation lifecycle:

1. User presses Start.
2. App requests a session from the backend.
3. Backend validates authentication.
4. Backend checks daily allowance and entitlement.
5. Backend reserves permitted usage.
6. Backend creates an authorized Gemini session.
7. Flutter connects using the supported realtime audio transport.
8. AI tutor greets the learner.
9. Learner speaks.
10. Gemini processes audio and responds with speech.
11. Transcript events are displayed where available.
12. Conversation continues naturally.
13. Learner can interrupt or pause where supported.
14. Learner ends the conversation.
15. Backend finalizes usage.
16. Post-session analysis begins.

Tutor behavior:
- Ask one question at a time.
- Avoid long monologues.
- Encourage the learner to speak.
- Follow up naturally.
- Adjust difficulty.
- Avoid correcting every mistake during live dialogue.
- Keep corrections for the feedback screen.

Error handling:
- Connection lost.
- Microphone denied.
- Session expired.
- Daily allowance exhausted.
- AI provider unavailable.
- Reconnection failure.

Never leave the user stuck in an indefinite loading state.

# 11. Session Ending

When the user presses End:

- Confirm only if necessary.
- Stop audio capture.
- Close the realtime session.
- Finalize server-side usage.
- Request or trigger post-session analysis.
- Save conversation metadata.
- Navigate to feedback.

The server must handle duplicate end requests safely.

If the app closes unexpectedly, server-side session expiry and usage reconciliation must still work.

# 12. Post-Session Feedback

Corrections must only be shown after the conversation ends.

Display:

**Session summary**
- Practice duration.
- Tutor.
- Scenario.
- Topics discussed.

**What you did well**
- Positive learning observations.
- Useful phrases.
- Effective communication examples.

**Grammar corrections**

Example:

Original:
"I am working as a software developer since 10 years."

Improved:
"I have been working as a software developer for 10 years."

Explanation:
Use the present perfect continuous for an action that began in the past and continues now. Use "for" to describe the duration.

**Vocabulary**
- New terms.
- Meanings.
- Example sentences.

**Communication tips**
- Better ways to express ideas.
- More natural alternatives.
- Suggestions for clarity.

**Next practice**
- Suggested topic.
- Suggested vocabulary.
- Relevant mistake review.

Do not fabricate corrections. Only show corrections supported by the conversation and analysis confidence.

Pronunciation assessment should appear only when a validated assessment system supports it.

# 13. Mistake Vault

Purpose: help learners recognize and improve recurring mistakes.

Each entry:

- Original sentence.
- Improved sentence.
- Explanation.
- Category.
- First occurrence.
- Last occurrence.
- Occurrence count.
- Review status.

Categories:
- Grammar.
- Vocabulary.
- Sentence structure.
- Word choice.
- Communication clarity.

Actions:
- Review.
- Practice again.
- Mark as learned.
- View related sessions.

# 14. Vocabulary

Each saved word or phrase includes:

- Term.
- Meaning.
- Example.
- Source conversation.
- Date added.
- Review status.
- Next review date.

Use a simple spaced-repetition approach.

Do not overwhelm learners with too many new words in one session.

# 15. Progress Screen

Show:

- Total speaking minutes.
- Number of completed sessions.
- Daily and weekly practice.
- Current streak.
- Vocabulary learned.
- Mistakes reviewed.
- Practice category distribution.
- Recent learning improvements.

Weekly report:
- What the learner practiced.
- Useful phrases learned.
- Repeated mistakes.
- Areas of improvement.
- Recommended next week's practice.

Avoid unsupported claims such as "Your English is now B2" without validated assessment evidence.

# 16. Subscription and Paywall

Free plan:
- 10 minutes of AI speaking per local calendar day.
- Basic tutors and scenarios.
- Basic post-session feedback.
- Basic progress.
- Limited history.
- Appropriate advertising.

Premium plan:
- Higher configurable usage allowance.
- Advanced scenarios.
- Detailed feedback.
- Full learning history.
- Professional communication pathways.
- Ad-free experience.

Initial pricing hypotheses:
- Monthly: $5.99.
- Annual: $39.99.

These are test prices, not final global pricing.

Paywall triggers:
- User reaches free allowance.
- User selects a premium-only scenario.
- User explicitly selects Upgrade.

Never interrupt an active conversation with a paywall or advertisement.

RevenueCat is the subscription integration.

Backend entitlement verification is authoritative.

# 17. Profile and Settings

Sections:
- Personal profile.
- Native language.
- Interface language.
- English level.
- Learning goals.
- Daily practice target.
- Preferred accent.
- Preferred tutor.
- Notification settings.
- Subscription management.
- Privacy settings.
- Data export, where supported.
- Account deletion.
- Sign out.

Account deletion must remove or anonymize associated user data according to the published retention policy and applicable legal requirements.

# 18. Error and Empty States

Every major screen must have:

- Loading state.
- Empty state.
- Error state.
- Retry action.
- Offline state where appropriate.

Examples:

No vocabulary:
"You haven't saved any vocabulary yet. Start a conversation to discover useful new words."

No mistakes:
"Great! No saved corrections yet. Your feedback will appear here after practice."

No internet:
"You're offline. Check your connection and try again."

Quota exhausted:
"You've completed today's free speaking time. Come back tomorrow or explore Premium."

# 19. Important User Journeys

## Journey A — First-time learner

```text
Welcome
  ↓
Sign in
  ↓
Select interface language
  ↓
Select native language
  ↓
Choose learning goals
  ↓
Select English level
  ↓
Set daily goal
  ↓
Select accent
  ↓
View learning plan
  ↓
Home
  ↓
Select Emma
  ↓
Start conversation
  ↓
Speak with Emma
  ↓
End session
  ↓
View feedback
  ↓
Save corrections and vocabulary
  ↓
Home
```

## Journey B — Returning learner

```text
Open App
  ↓
Authentication
  ↓
Home
  ↓
View daily progress
  ↓
Review recommended mistakes
  ↓
Start speaking
  ↓
Select tutor / scenario
  ↓
Conversation
  ↓
Feedback
  ↓
Progress updated
```

## Journey C — Job interview practice

```text
Home
  ↓
Practice
  ↓
Professional
  ↓
Job Interview
  ↓
Select Alex
  ↓
Select difficulty
  ↓
Start conversation
  ↓
AI interviewer asks questions
  ↓
Learner answers
  ↓
AI follows up
  ↓
End conversation
  ↓
Interview feedback
  ↓
Review improved answers
  ↓
Repeat practice
```

## Journey D — Daily free allowance exhausted

```text
Start Speaking
  ↓
Backend checks allowance
  ↓
No remaining allowance
  ↓
Show daily limit message
  ↓
Offer Premium
  ↓
User chooses:
  ├── View Premium
  └── Return Home
```

Do not start an AI session if no permitted usage remains.

## Journey E — Premium purchase

```text
Premium scenario / Upgrade
  ↓
Paywall
  ↓
Select monthly or annual
  ↓
RevenueCat purchase
  ↓
Backend entitlement verification
  ↓
Premium activated
  ↓
Return to previous activity
```

Do not unlock premium solely because the client reports a successful purchase.

# 20. UX Design Guidelines

Visual direction:
- Clean light theme.
- Friendly and modern.
- Calm and encouraging.
- Accessible typography.
- Rounded cards and buttons.
- Clear information hierarchy.
- Consistent spacing.
- Subtle animations.
- Minimal visual clutter.

The primary call to action should be obvious.

The conversation screen should prioritize the learner's voice interaction rather than decorative elements.

Design for different screen sizes.

Use localization-ready text resources.

Do not hardcode English strings directly throughout widgets.

# 21. Analytics Events

Track:

- sign_up_started
- sign_up_completed
- onboarding_completed
- tutor_selected
- scenario_selected
- conversation_started
- conversation_completed
- conversation_abandoned
- feedback_viewed
- correction_saved
- vocabulary_saved
- daily_goal_completed
- free_limit_reached
- paywall_viewed
- subscription_completed
- rewarded_ad_completed

Do not send raw audio, transcripts or sensitive user data to analytics.

# 22. User Experience Acceptance Criteria

The MVP is ready for internal testing when:

1. A new user can register.
2. Onboarding preferences are saved.
3. The user can reach Home.
4. The user can select an AI tutor.
5. The user can select a scenario.
6. The user can start a realtime voice session.
7. The learner and tutor can communicate naturally.
8. The conversation can be interrupted and ended safely.
9. Usage is enforced server-side.
10. Post-session feedback is generated.
11. Corrections can be saved.
12. Vocabulary can be saved.
13. Progress is updated.
14. The user can view profile and settings.
15. Data access is protected by authentication and authorization.
16. Account deletion works according to policy.

**End of app flow specification.**