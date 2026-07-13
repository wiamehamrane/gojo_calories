export const API_URL =
  process.env.NEXT_PUBLIC_API_URL || "https://api.gojocalories.com/api";

export interface AdminUser {
  id: string;
  email: string;
  name: string | null;
  is_email_verified: boolean;
  is_admin: boolean;
  is_banned: boolean;
  has_paid: boolean;
  subscription_source: string | null;
  subscription_expires_at: string | null;
  current_weight: number | null;
  goal_weight: number | null;
  referral_code: string | null;
  referral_balance: number;
  stripe_customer_id: string | null;
}

export interface DashboardStats {
  total_users: number;
  verified_users: number;
  paid_users: number;
  banned_users: number;
  total_food_logs: number;
  total_exercises: number;
  total_events: number;
  total_posts: number;
  total_memories: number;
  total_groups: number;
  pending_withdrawals: number;
  total_influencers: number;
  active_influencers: number;
  total_promo_redemptions: number;
  active_promo_codes: number;
  subscription_breakdown: Record<string, number>;
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
}

export interface UserDetail extends AdminUser {
  height?: number | null;
  height_unit?: string | null;
  age?: number | null;
  gender?: string | null;
  activity_level?: string | null;
  weight_unit?: string | null;
  manual_calories?: number | null;
  manual_protein?: number | null;
  manual_carbs?: number | null;
  manual_fat?: number | null;
  phone?: string | null;
  apple_original_transaction_id?: string | null;
  google_order_id?: string | null;
  counts?: {
    food_logs: number;
    exercises: number;
    events_created: number;
    posts: number;
    memories: number;
    referrals: number;
  };
}

export interface FoodLog {
  id: string;
  user_id: string;
  name: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  image_url: string | null;
  created_at: string | null;
}

export interface EventItem {
  id: string;
  creator_id: string;
  title: string;
  event_type: string;
  audience: string;
  location_name: string | null;
  start_time: string | null;
  max_participants: number | null;
  participant_count: number;
  image_url: string | null;
  created_at: string | null;
}

export interface PostItem {
  id: string;
  user_id: string;
  content: string | null;
  image_url: string | null;
  like_count: number;
  created_at: string | null;
}

export interface MemoryItem {
  id: string;
  user_id: string;
  caption: string | null;
  image_url: string;
  is_private: boolean;
  created_at: string | null;
}

export interface GroupItem {
  id: string;
  name: string;
  description: string | null;
  member_count: number;
  created_at: string | null;
}

export interface ReferralItem {
  id: string;
  referrer_id: string;
  referrer_email: string | null;
  referred_user_id: string;
  referred_email: string | null;
  amount: number;
  created_at: string | null;
}

export interface WithdrawalItem {
  id: string;
  user_id: string;
  user_email: string | null;
  amount: number;
  method: string;
  status: string;
  created_at: string | null;
}

export interface ExerciseItem {
  id: string;
  user_id: string;
  name: string;
  duration_minutes: number;
  calories_burned: number;
  date: string | null;
}
