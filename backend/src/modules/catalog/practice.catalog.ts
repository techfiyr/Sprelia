import type { CefrLevel } from './tutors.catalog.js';

/**
 * Practice categories and scenarios (APP_FLOW §8).
 *
 * Content status: DRAFT written by engineering for Phase 2, pending review by the
 * product/learning owner. Objectives and vocabulary are deliberately short.
 */
export interface Scenario {
  id: string;
  title: string;
  description: string;
  cefr: { min: CefrLevel; max: CefrLevel };
  objectives: string[];
  estimatedMinutes: number;
  suggestedTutorId: string;
  vocabulary: string[];
  premium: boolean;
}

export interface PracticeCategory {
  id: string;
  title: string;
  description: string;
  /** Icon key mapped to a Material icon by the app. */
  icon: 'everyday' | 'professional' | 'academic' | 'travel' | 'social';
  scenarios: Scenario[];
}

const s = (
  id: string,
  title: string,
  description: string,
  cefr: [CefrLevel, CefrLevel],
  suggestedTutorId: string,
  objectives: string[],
  vocabulary: string[],
  estimatedMinutes = 5,
): Scenario => ({
  id,
  title,
  description,
  cefr: { min: cefr[0], max: cefr[1] },
  objectives,
  estimatedMinutes,
  suggestedTutorId,
  vocabulary,
  premium: false,
});

export const PRACTICE_CATEGORIES: readonly PracticeCategory[] = [
  {
    id: 'everyday',
    title: 'Everyday',
    description: 'Talk about yourself and your daily life.',
    icon: 'everyday',
    scenarios: [
      s('introductions', 'Introductions', 'Introduce yourself and get to know someone new.', ['A1', 'B1'], 'emma',
        ['Say who you are and where you are from', 'Ask simple follow-up questions'], ['nice to meet you', 'originally from', 'for a living']),
      s('daily-routines', 'Daily routines', 'Describe a typical day and your habits.', ['A1', 'B1'], 'emma',
        ['Describe your routine in order', 'Use time expressions naturally'], ['usually', 'on weekdays', 'after work', 'get ready']),
      s('hobbies', 'Hobbies', 'Share what you enjoy doing in your free time.', ['A1', 'B2'], 'sofia',
        ['Explain why you enjoy something', 'Ask about other people’s interests'], ['I’m really into', 'in my free time', 'give it a try']),
      s('shopping', 'Shopping', 'Ask about products, sizes and prices.', ['A1', 'B1'], 'sofia',
        ['Ask for help in a shop', 'Compare options politely'], ['do you have this in', 'how much is', 'I’m just looking', 'receipt']),
      s('food-restaurants', 'Food and restaurants', 'Order a meal and talk about food.', ['A1', 'B2'], 'sofia',
        ['Order politely', 'Ask about ingredients', 'Handle a small problem'], ['could I have', 'I’d like', 'the bill, please', 'allergic to']),
    ],
  },
  {
    id: 'professional',
    title: 'Professional',
    description: 'Communicate clearly at work.',
    icon: 'professional',
    scenarios: [
      s('job-interviews', 'Job interviews', 'Answer common interview questions with confidence.', ['A2', 'C1'], 'alex',
        ['Introduce your experience clearly', 'Give examples with results', 'Ask the interviewer a question'], ['I’m responsible for', 'one example is', 'strengths', 'I’d welcome the chance'], 8),
      s('office-conversations', 'Office conversations', 'Chat with colleagues and ask for help.', ['A2', 'B2'], 'alex',
        ['Make polite requests', 'Make small talk at work'], ['do you have a minute', 'could you help me with', 'deadline']),
      s('meetings', 'Meetings', 'Share updates, agree and disagree politely.', ['B1', 'C1'], 'alex',
        ['Give a short status update', 'Agree and disagree politely'], ['to give a quick update', 'I see your point, but', 'action items'], 8),
      s('presentations', 'Presentations', 'Introduce a topic and guide your listeners.', ['B1', 'C1'], 'alex',
        ['Open and structure a short talk', 'Handle a question'], ['today I’ll talk about', 'moving on to', 'to sum up'], 8),
      s('client-communication', 'Client communication', 'Talk to clients about needs and next steps.', ['B1', 'C1'], 'alex',
        ['Understand a client’s needs', 'Confirm next steps'], ['just to confirm', 'what are your priorities', 'follow up']),
    ],
  },
  {
    id: 'academic',
    title: 'Academic',
    description: 'Discuss ideas for study and research.',
    icon: 'academic',
    scenarios: [
      s('classroom-discussion', 'Classroom discussion', 'Share your opinion in a class discussion.', ['A2', 'B2'], 'alex',
        ['Give an opinion with a reason', 'Respond to another view'], ['in my opinion', 'that’s a good point', 'on the other hand']),
      s('study-abroad', 'Study abroad', 'Talk about studying in another country.', ['A2', 'B2'], 'emma',
        ['Explain your study plans', 'Ask practical questions'], ['enrol', 'accommodation', 'course requirements']),
      s('explaining-ideas', 'Explaining ideas', 'Explain a topic you know well in simple words.', ['B1', 'C1'], 'alex',
        ['Explain step by step', 'Check that the listener understands'], ['in other words', 'for example', 'does that make sense']),
      s('academic-discussions', 'Academic discussions', 'Discuss research and evidence.', ['B2', 'C1'], 'alex',
        ['Summarise an argument', 'Ask for clarification'], ['the evidence suggests', 'to what extent', 'could you clarify'], 8),
    ],
  },
  {
    id: 'travel',
    title: 'Travel',
    description: 'Handle travel situations with ease.',
    icon: 'travel',
    scenarios: [
      s('airport', 'At the airport', 'Check in, go through security and find your gate.', ['A1', 'B1'], 'emma',
        ['Check in for a flight', 'Ask where to go'], ['boarding pass', 'carry-on', 'gate', 'delayed']),
      s('hotel-check-in', 'Hotel check-in', 'Check in and ask about your room.', ['A1', 'B1'], 'sofia',
        ['Give your booking details', 'Ask about hotel services'], ['I have a reservation', 'check-out time', 'is breakfast included']),
      s('asking-directions', 'Asking for directions', 'Ask for and follow directions.', ['A1', 'B1'], 'emma',
        ['Ask politely for directions', 'Check that you understood'], ['excuse me', 'how do I get to', 'turn left', 'opposite']),
      s('travel-problems', 'Travel problems', 'Solve a problem like a lost bag or a missed train.', ['A2', 'B2'], 'sofia',
        ['Explain what happened', 'Ask for a solution'], ['my luggage didn’t arrive', 'what are my options', 'refund']),
    ],
  },
  {
    id: 'social',
    title: 'Social',
    description: 'Make connections and enjoy conversations.',
    icon: 'social',
    scenarios: [
      s('making-friends', 'Making friends', 'Start a friendly conversation and find common ground.', ['A1', 'B2'], 'sofia',
        ['Show interest in the other person', 'Suggest meeting again'], ['what about you', 'we should', 'that sounds fun']),
      s('networking', 'Networking', 'Introduce yourself at a professional event.', ['B1', 'C1'], 'alex',
        ['Give a short introduction', 'Keep the conversation going'], ['what brings you here', 'I work in', 'let’s keep in touch']),
      s('small-talk', 'Small talk', 'Chat about the weather, weekends and plans.', ['A1', 'B2'], 'sofia',
        ['Start and end small talk naturally', 'Ask open questions'], ['how was your weekend', 'any plans for', 'it was nice talking to you']),
      s('social-events', 'Social events', 'Talk with people at a party or gathering.', ['A2', 'B2'], 'sofia',
        ['Join a group conversation', 'Share a short story'], ['how do you know', 'that reminds me', 'I’d better get going']),
    ],
  },
];

export function findScenario(id: string): { category: PracticeCategory; scenario: Scenario } | undefined {
  for (const category of PRACTICE_CATEGORIES) {
    const scenario = category.scenarios.find((x) => x.id === id);
    if (scenario) return { category, scenario };
  }
  return undefined;
}
