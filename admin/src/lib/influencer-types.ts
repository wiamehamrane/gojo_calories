export interface Influencer {
  id: string;
  user_id: string;
  email: string | null;
  name: string | null;
  display_name: string;
  handle: string | null;
  platform: string | null;
  notes: string | null;
  commission_rate: number | null;
  panel_access: boolean;
  is_active: boolean;
  has_paid: boolean;
  subscription_source: string | null;
  subscription_expires_at: string | null;
  created_at: string | null;
}

export type InfluencerDetail = Influencer;
