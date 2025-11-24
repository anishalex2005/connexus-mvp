declare global {
  namespace Express {
    interface Request {
      id?: string;
      user?: {
        id: string;
        email: string;
        role: string;
      };
    }
  }
}

export interface User {
  id: string;
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  phoneNumbers: PhoneNumber[];
  createdAt: Date;
  updatedAt: Date;
}

export interface PhoneNumber {
  id: string;
  userId: string;
  number: string;
  isPrimary: boolean;
  isVerified: boolean;
  createdAt: Date;
}

export interface Call {
  id: string;
  userId: string;
  phoneNumber: string;
  direction: 'inbound' | 'outbound';
  status: 'initiated' | 'ringing' | 'answered' | 'completed' | 'failed';
  duration: number;
  startTime: Date;
  endTime?: Date;
  recordingUrl?: string;
  transcript?: string;
}

export interface AIConfig {
  id: string;
  userId: string;
  agentName: string;
  personality: string;
  greeting: string;
  businessHours: BusinessHours;
  knowledgeBase: KnowledgeBaseItem[];
}

export interface BusinessHours {
  timezone: string;
  schedule: {
    [key: string]: {
      open: string;
      close: string;
    };
  };
}

export interface KnowledgeBaseItem {
  id: string;
  question: string;
  answer: string;
  category: string;
}

export interface SMSTemplate {
  id: string;
  userId: string;
  name: string;
  content: string;
  variables: string[];
  category: string;
}

export interface ApiResponse<T = any> {
  status: 'success' | 'fail' | 'error';
  message?: string;
  data?: T;
  error?: any;
}

export {};
