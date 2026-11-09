import type { CefrLevel } from './tutors.catalog.js';

/**
 * Practice categories and scenarios (APP_FLOW §8), base content in **American English**
 * (owner decision 2026-11-09). Other English variants are added as text overlays in
 * `content-variants.ts`; the structure (ids, levels, tutors, premium) stays here.
 *
 * Publishing rule (owner decision): every scenario needs HUMAN REVIEW before it is
 * published. `reviewStatus: 'draft'` scenarios are served only in development, test and
 * staging; production serves `approved` scenarios only (see catalog.service.ts).
 * Approving means: a named reviewer checked the content, then set `reviewStatus:
 * 'approved'` with `reviewedBy` and `reviewedAt` in a reviewed commit.
 */
export type ReviewStatus = 'draft' | 'approved';

/** Allowed estimated durations in minutes (owner decision: 5, 10 and 15). */
export const SCENARIO_DURATIONS = [5, 10, 15] as const;

export interface Scenario {
  id: string;
  title: string;
  description: string;
  cefr: { min: CefrLevel; max: CefrLevel };
  objectives: string[];
  estimatedMinutes: (typeof SCENARIO_DURATIONS)[number];
  suggestedTutorId: string;
  vocabulary: string[];
  premium: boolean;
  reviewStatus: ReviewStatus;
  reviewedBy?: string;
  reviewedAt?: string;
}

export interface PracticeCategory {
  id: string;
  title: string;
  description: string;
  /** Icon key mapped to a Material icon by the app. */
  icon: 'everyday' | 'professional' | 'academic' | 'travel' | 'social';
  scenarios: Scenario[];
}

interface Spec {
  title: string;
  description: string;
  cefr: [CefrLevel, CefrLevel];
  tutor: string;
  objectives: string[];
  vocabulary: string[];
  minutes?: Scenario['estimatedMinutes'];
  premium?: boolean;
}

const s = (id: string, spec: Spec): Scenario => ({
  id,
  title: spec.title,
  description: spec.description,
  cefr: { min: spec.cefr[0], max: spec.cefr[1] },
  objectives: spec.objectives,
  estimatedMinutes: spec.minutes ?? 5,
  suggestedTutorId: spec.tutor,
  vocabulary: spec.vocabulary,
  premium: spec.premium ?? false,
  // No scenario has had human review yet (Phase 2 close-out, 2026-11-09).
  reviewStatus: 'draft',
});

export const PRACTICE_CATEGORIES: readonly PracticeCategory[] = [
  {
    id: 'everyday',
    title: 'Everyday',
    description: 'Talk about yourself and your daily life.',
    icon: 'everyday',
    scenarios: [
      s('introductions', {
        title: 'Introductions', description: 'Introduce yourself and get to know someone new.', cefr: ['A1', 'B1'], tutor: 'emma',
        objectives: ['Say who you are and where you are from', 'Ask simple follow-up questions'],
        vocabulary: ['nice to meet you', 'originally from', 'for a living'],
      }),
      s('daily-routines', {
        title: 'Daily routines', description: 'Describe a typical day and your habits.', cefr: ['A1', 'B1'], tutor: 'emma',
        objectives: ['Describe your routine in order', 'Use time expressions naturally'],
        vocabulary: ['usually', 'on weekdays', 'after work', 'get ready'],
      }),
      s('hobbies', {
        title: 'Hobbies', description: 'Share what you enjoy doing in your free time.', cefr: ['A1', 'B2'], tutor: 'sofia',
        objectives: ['Explain why you enjoy something', 'Ask about other people’s interests'],
        vocabulary: ['I’m really into', 'in my free time', 'give it a try'],
      }),
      s('shopping', {
        title: 'Shopping', description: 'Ask about products, sizes and prices.', cefr: ['A1', 'B1'], tutor: 'sofia',
        objectives: ['Ask for help in a store', 'Compare options politely'],
        vocabulary: ['do you have this in', 'how much is', 'I’m just looking', 'receipt'],
      }),
      s('food-restaurants', {
        title: 'Food and restaurants', description: 'Order a meal and talk about food.', cefr: ['A1', 'B2'], tutor: 'sofia',
        objectives: ['Order politely', 'Ask about ingredients', 'Handle a small problem'],
        vocabulary: ['could I have', 'I’d like', 'the check, please', 'allergic to'],
      }),
    ],
  },
  {
    id: 'professional',
    title: 'Professional',
    description: 'Communicate clearly at work.',
    icon: 'professional',
    scenarios: [
      s('talking-about-work', {
        title: 'Talking about your job', description: 'Say what you do and describe your workday in simple words.', cefr: ['A1', 'A2'], tutor: 'emma',
        objectives: ['Say your job and where you work', 'Describe what you do on a normal day'],
        vocabulary: ['I work as', 'my job is', 'I work at', 'coworker'],
      }),
      s('job-interviews', {
        title: 'Job interviews', description: 'Answer common interview questions with confidence.', cefr: ['A2', 'C1'], tutor: 'alex', minutes: 10,
        objectives: ['Introduce your experience clearly', 'Give examples with results', 'Ask the interviewer a question'],
        vocabulary: ['I’m responsible for', 'one example is', 'strengths', 'I’d welcome the chance'],
      }),
      s('office-conversations', {
        title: 'Office conversations', description: 'Chat with coworkers and ask for help.', cefr: ['A2', 'B2'], tutor: 'alex',
        objectives: ['Make polite requests', 'Make small talk at work'],
        vocabulary: ['do you have a minute', 'could you help me with', 'deadline'],
      }),
      s('meetings', {
        title: 'Meetings', description: 'Share updates, agree and disagree politely.', cefr: ['B1', 'C1'], tutor: 'alex', minutes: 10,
        objectives: ['Give a short status update', 'Agree and disagree politely'],
        vocabulary: ['to give a quick update', 'I see your point, but', 'action items'],
      }),
      s('presentations', {
        title: 'Presentations', description: 'Introduce a topic and guide your listeners.', cefr: ['B1', 'C1'], tutor: 'alex', minutes: 10, premium: true,
        objectives: ['Open and structure a short talk', 'Handle a question'],
        vocabulary: ['today I’ll talk about', 'moving on to', 'to sum up'],
      }),
      s('client-communication', {
        title: 'Client communication', description: 'Talk to clients about needs and next steps.', cefr: ['B1', 'C1'], tutor: 'alex', premium: true,
        objectives: ['Understand a client’s needs', 'Confirm next steps'],
        vocabulary: ['just to confirm', 'what are your priorities', 'follow up'],
      }),
    ],
  },
  {
    id: 'academic',
    title: 'Academic',
    description: 'Discuss ideas for study and research.',
    icon: 'academic',
    scenarios: [
      s('classroom-basics', {
        title: 'Classroom basics', description: 'Ask simple questions and talk about your classes.', cefr: ['A1', 'A2'], tutor: 'emma',
        objectives: ['Ask the teacher to repeat or explain', 'Talk about your subjects and schedule'],
        vocabulary: ['could you repeat that', 'what does … mean', 'homework', 'my favorite subject'],
      }),
      s('classroom-discussion', {
        title: 'Classroom discussion', description: 'Share your opinion in a class discussion.', cefr: ['A2', 'B2'], tutor: 'alex',
        objectives: ['Give an opinion with a reason', 'Respond to another view'],
        vocabulary: ['in my opinion', 'that’s a good point', 'on the other hand'],
      }),
      s('study-abroad', {
        title: 'Study abroad', description: 'Talk about studying in another country.', cefr: ['A2', 'B2'], tutor: 'alex',
        objectives: ['Explain your study plans', 'Ask practical questions'],
        vocabulary: ['enroll', 'housing', 'course requirements'],
      }),
      s('explaining-ideas', {
        title: 'Explaining ideas', description: 'Explain a topic you know well in simple words.', cefr: ['B1', 'C1'], tutor: 'alex',
        objectives: ['Explain step by step', 'Check that the listener understands'],
        vocabulary: ['in other words', 'for example', 'does that make sense'],
      }),
      s('academic-discussions', {
        title: 'Academic discussions', description: 'Discuss research and evidence.', cefr: ['B2', 'C1'], tutor: 'alex', minutes: 10, premium: true,
        objectives: ['Summarize an argument', 'Ask for clarification'],
        vocabulary: ['the evidence suggests', 'to what extent', 'could you clarify'],
      }),
    ],
  },
  {
    id: 'travel',
    title: 'Travel',
    description: 'Handle travel situations with ease.',
    icon: 'travel',
    scenarios: [
      s('airport', {
        title: 'At the airport', description: 'Check in, go through security and find your gate.', cefr: ['A1', 'B1'], tutor: 'emma',
        objectives: ['Check in for a flight', 'Ask where to go'],
        vocabulary: ['boarding pass', 'carry-on', 'gate', 'delayed'],
      }),
      s('hotel-check-in', {
        title: 'Hotel check-in', description: 'Check in and ask about your room.', cefr: ['A1', 'B1'], tutor: 'sofia',
        objectives: ['Give your booking details', 'Ask about hotel services'],
        vocabulary: ['I have a reservation', 'checkout time', 'is breakfast included'],
      }),
      s('asking-directions', {
        title: 'Asking for directions', description: 'Ask for and follow directions.', cefr: ['A1', 'B1'], tutor: 'emma',
        objectives: ['Ask politely for directions', 'Check that you understood'],
        vocabulary: ['excuse me', 'how do I get to', 'turn left', 'across from'],
      }),
      s('travel-problems', {
        title: 'Travel problems', description: 'Solve a problem like a lost bag or a missed train.', cefr: ['A2', 'B2'], tutor: 'sofia',
        objectives: ['Explain what happened', 'Ask for a solution'],
        vocabulary: ['my luggage didn’t arrive', 'what are my options', 'refund'],
      }),
      s('trip-planning', {
        title: 'Planning a trip', description: 'Compare destinations and make plans with a travel partner.', cefr: ['B1', 'B2'], tutor: 'sofia',
        objectives: ['Compare options and give reasons', 'Agree on a plan together'],
        vocabulary: ['it might be better to', 'what if we', 'itinerary', 'on a budget'],
      }),
      s('changing-plans', {
        title: 'Changing travel plans', description: 'Rebook a flight or hotel and negotiate a fair solution.', cefr: ['B1', 'B2'], tutor: 'sofia',
        objectives: ['Explain why you need to change plans', 'Negotiate options politely'],
        vocabulary: ['I’d like to rebook', 'is there a fee', 'the earliest available', 'I’d appreciate it if'],
      }),
      s('local-culture', {
        title: 'Exploring local culture', description: 'Discuss customs, food and traditions with a local.', cefr: ['B2', 'B2'], tutor: 'sofia', minutes: 10, premium: true,
        objectives: ['Ask thoughtful questions about local customs', 'Compare traditions with your own culture'],
        vocabulary: ['what’s the story behind', 'where I’m from', 'it’s customary to', 'I was surprised that'],
      }),
    ],
  },
  {
    id: 'social',
    title: 'Social',
    description: 'Make connections and enjoy conversations.',
    icon: 'social',
    scenarios: [
      s('making-friends', {
        title: 'Making friends', description: 'Start a friendly conversation and find common ground.', cefr: ['A1', 'B2'], tutor: 'sofia',
        objectives: ['Show interest in the other person', 'Suggest meeting again'],
        vocabulary: ['what about you', 'we should', 'that sounds fun'],
      }),
      s('networking', {
        title: 'Networking', description: 'Introduce yourself at a professional event.', cefr: ['B1', 'C1'], tutor: 'alex',
        objectives: ['Give a short introduction', 'Keep the conversation going'],
        vocabulary: ['what brings you here', 'I work in', 'let’s keep in touch'],
      }),
      s('small-talk', {
        title: 'Small talk', description: 'Chat about the weather, weekends and plans.', cefr: ['A1', 'B2'], tutor: 'sofia',
        objectives: ['Start and end small talk naturally', 'Ask open questions'],
        vocabulary: ['how was your weekend', 'any plans for', 'it was nice talking to you'],
      }),
      s('social-events', {
        title: 'Social events', description: 'Talk with people at a party or gathering.', cefr: ['A2', 'B2'], tutor: 'sofia', premium: true,
        objectives: ['Join a group conversation', 'Share a short story'],
        vocabulary: ['how do you know', 'that reminds me', 'I’d better get going'],
      }),
    ],
  },
];
