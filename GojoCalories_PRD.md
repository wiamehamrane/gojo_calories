  
**GojoCalories**

*AI-Powered Calorie & Nutrition Tracker*

| Document Type | Product Requirements Document (PRD) |
| :---- | :---- |
| **Product Name** | GojoCalories |
| **Version** | 1.0 — Initial Release |
| **Status** | Draft — For Internal Review |
| **Date** | April 2026 |
| **Author** | Product Team |
| **Platform** | iOS & Android (React Native) |
| **Target Launch** | Q3 2026 |

# **1\. Executive Summary**

GojoCalories is a mobile-first, AI-powered nutrition tracking app designed to eliminate the friction of calorie counting. By leveraging on-device AI and computer vision, users can log any meal in under 5 seconds — simply by taking a photo. The app delivers instant, accurate breakdowns of calories and macronutrients (protein, carbs, fat), paired with a deeply personalized plan built from each user's body metrics, goals, and lifestyle.

The product targets the mass-market health-conscious consumer: people who want to lose weight, build muscle, or simply eat better — but find traditional calorie tracking too tedious to stick with. GojoCalories removes every point of friction between the user and the data they need.

| Mission Statement Make accurate nutrition tracking effortless for everyone — regardless of their diet, cooking style, or fitness experience. |
| :---- |

# **2\. Product Overview**

## **2.1 Vision**

GojoCalories will be the fastest, most accurate, and most enjoyable way to track food intake on mobile. It should feel less like a logging tool and more like a personal nutrition coach that lives in your pocket.

## **2.2 Core Value Proposition**

* Photo-first logging — snap a meal, get instant nutritional data in under 5 seconds

* Deeply personalized onboarding that generates a unique calorie and macro plan per user

* Multi-modal food entry: camera, barcode scan, voice, text search, manual entry

* Real-time progress analytics with weight tracking, BMI, and goal projections

* Social accountability through Groups (friends, family, public challenges)

* Integrations with Apple Health, Google Fit, and Apple Watch

## **2.3 Target Platforms**

| iOS | iOS 17.0+  (iPhone, iPad, Apple Watch, Apple Vision) |
| :---- | :---- |
| **Android** | Android 10+  (Phone, Tablet, Wear OS) |
| **Framework** | React Native (shared codebase, native modules for camera & ML) |
| **Backend** | Node.js / GraphQL API, PostgreSQL, Redis cache, AWS S3 (media) |
| **AI Model** | Custom fine-tuned vision model \+ third-party LLM fallback |

# **3\. Target Users & Personas**

## **3.1 Primary Personas**

| Alex, 26 — Weight Loss | Jordan, 31 — Muscle Gain | Sam, 22 — Healthy Habits |
| :---- | :---- | :---- |
| Wants to lose 20 lbs. Hates calorie math. Eats out frequently. Needs something fast and forgiving. | Tracks macros obsessively. Needs precise protein targets. Wants exercise-calorie offset visibility. | Health-conscious but not a fitness junkie. Wants visual progress without the overwhelm. |

## **3.2 User Needs & Pain Points**

* Manual food entry in existing apps is too slow and abandoned within days

* Portion estimation is hard — users don't own food scales

* Most apps feel clinical and joyless; motivation drops quickly

* No easy way to track homemade or restaurant meals

* Progress feels invisible — users don't know if what they're doing is working

# **4\. Feature Requirements**

## **4.1 Feature Priority Matrix**

| Feature | Priority | Effort | Sprint |
| :---- | ----- | ----- | ----- |
| Onboarding quiz (25-step personalized flow) | **P0** | L | S1 |
| AI photo food scanning | **P0** | XL | S1 |
| Daily calorie & macro dashboard | **P0** | L | S1 |
| Hard paywall / free trial (3-day) | **P0** | M | S1 |
| Barcode scanner | **P0** | M | S1 |
| Food database search (1M+ items) | **P0** | XL | S1 |
| Manual food entry & custom foods | **P1** | M | S2 |
| Exercise logging | **P1** | M | S2 |
| Progress & analytics screen | **P1** | L | S2 |
| Weight logging & chart | **P1** | M | S2 |
| Apple Health / Google Fit sync | **P1** | M | S2 |
| Progress photos | **P1** | S | S3 |
| Groups (social accountability) | **P2** | L | S3 |
| Family plan (up to 5 members) | **P2** | M | S3 |
| Referral program | **P2** | S | S3 |
| Apple Watch / Wear OS app | **P2** | L | S4 |
| Home screen widgets | **P2** | M | S4 |
| Rollover calories | **P3** | S | S4 |
| AI nutrition coach chat | **P3** | XL | S4 |
| Restaurant menu photo scan | **P3** | L | S4 |

*Priority: P0 \= Launch blocker   P1 \= Core experience   P2 \= Growth feature   P3 \= Future*

*Effort: S \= Small (\<1 week)   M \= Medium (1–2 weeks)   L \= Large (2–4 weeks)   XL \= Extra-large (\>4 weeks)*

# **5\. Onboarding Flow**

The onboarding flow is one of GojoCalories' most critical conversion surfaces. It must simultaneously collect the data needed to generate a personalized plan AND build the user's confidence that this app will work for them. The flow ends with a hard paywall — the user cannot access core features without starting a free trial.

## **5.1 Onboarding Steps (25 screens)**

1. Splash / Welcome — logo, tagline, social proof badge, Get Started CTA

2. Social proof screen — animated weight-loss graph, testimonial quote, '91% of users reach their goal' stat

3. Goal selection — Lose Weight / Maintain / Gain Muscle (single-select cards)

4. Gender selection — Male / Female

5. Current weight input — scroll picker, lbs/kg toggle

6. Target weight input — scroll picker

7. Goal validation — 'Your goal is realistic' reassurance screen with motivational copy

8. Height input — ft/in or cm toggle

9. Age input — scroll picker or date wheel

10. Activity level — 5 options from Sedentary to Athlete

11. Diet preference — multi-select: None, Keto, Vegan, Vegetarian, IF, High-Protein, Gluten-Free

12. Workout frequency — Never / 1–2x / 3–4x / 5+ per week

13. Biggest challenge — multi-select: portions, eating out, snacking, consistency, meal knowledge

14. Notification opt-in — meal reminder pitch, 'Allow Notifications' CTA

15. Projected results — animated before/after weight curve with goal date

16. AI plan generation — animated loading screen ('Building your plan...')

17. Plan summary — editable daily calorie target, macro split

18. Testimonial carousel — influencer or real user social proof

19. Feature highlight 1 — AI photo scanning explainer

20. Feature highlight 2 — barcode \+ database explainer

21. Feature highlight 3 — progress & analytics explainer

22. Feature highlight 4 — groups & accountability explainer

23. Review prompt primer — 'People love GojoCalories' (pre-ratings nudge)

24. Account creation — email/password, Sign in with Apple, Sign in with Google

25. Paywall — 3-day free trial, Monthly vs Yearly plans, trial timeline graphic

| Onboarding Design Principles Never ask for more than one input per screen. Show a progress bar at all times — users must always know where they are. Validate the user's goal on screen 7 — never let them feel their target is 'too ambitious'. The plan summary (screen 17\) must be fully editable — AI as advisor, not dictator. Paywall must appear AFTER the user has seen their personalized plan and is invested. |
| :---- |

# **6\. Screen-by-Screen Specifications**

## **6.1 Authentication Screens**

| Sign Up Screen |  |
| :---- | :---- |
| **Purpose** | Create a new GojoCalories account |
| **Components** | App logo \+ welcome headline Email input field with validation Password input field with show/hide toggle and strength meter Primary CTA button: 'Create Account' Divider: 'or continue with' Sign in with Apple button (iOS) / Sign in with Google button 'Already have an account? Log in' link Privacy Policy \+ Terms of Use footer links |

| Log In Screen |  |
| :---- | :---- |
| **Purpose** | Authenticate returning users |
| **Components** | Email \+ password fields 'Forgot Password?' link below password field Log In primary button Sign in with Apple / Google buttons 'Don't have an account? Sign Up' link Biometric auth prompt on return visits (Face ID / Fingerprint) |

| Forgot Password Screen |  |
| :---- | :---- |
| **Purpose** | Trigger password reset via email |
| **Components** | Email input field 'Send Reset Link' primary CTA Confirmation state: 'Check your inbox' illustration \+ back to login link |

## **6.2 Home / Dashboard Screen**

| Home Screen (Main Dashboard) |  |
| :---- | :---- |
| **Purpose** | Daily nutrition overview and primary logging hub |
| **Top Bar** | Greeting: 'Good morning, \[First Name\]' Date selector (swipe left/right for adjacent days) Settings icon (top-right) |
| **Calorie Ring** | Large donut chart centered on screen Center text: calorie budget remaining (large number) \+ 'kcal left' label Ring segments color-coded: consumed vs remaining vs exercise bonus Tapping ring opens detailed calorie breakdown modal |
| **Macro Bar** | Three horizontal progress bars: Protein / Carbs / Fat Each shows grams consumed vs daily target Color-coded: protein \= blue, carbs \= orange, fat \= yellow Tap any bar to see full macro history for the day |
| **Meal Sections** | Collapsible sections: Breakfast / Lunch / Dinner / Snacks Each section shows total kcal consumed for that meal Logged food items listed with name, calories, and quantity Swipe-left on any item to delete '+ Add Food' row at bottom of each section (triggers Log Food screen) |
| **Water Tracker** | Water intake progress bar (goal: 2L default) Quick-add buttons: \+250ml / \+500ml Tap to open full water log modal with custom amount input |
| **Exercise Section** | Logged exercises shown with calories burned Burned calories reflected as a calorie budget bonus on the ring '+ Log Exercise' row |
| **Bottom Navigation** | 5 tabs: Home · Log · Progress · Groups · Profile |

## **6.3 Food Logging Screens**

| Add Food Screen (Log Food Modal) |  |
| :---- | :---- |
| **Purpose** | Entry point for all food logging — multi-modal |
| **Tab Bar** | 5 tabs: Camera | Barcode | Search | Recent | My Foods |
| **Camera Tab** | Full-screen camera viewfinder Large centered shutter button Flip camera icon (front/back) Torch/flash toggle Tip overlay: 'Hold camera over your meal' (dismissible) Gallery picker shortcut (bottom-left) |
| **Barcode Tab** | Scanning frame with animated corner guides Torch toggle Manual barcode entry fallback link Auto-triggers result on successful scan |
| **Search Tab** | Prominent search bar (auto-focused) Recent searches chips Results list: food name, brand (if applicable), kcal per serving, serving unit Filter / sort option (by relevance, brand, calories) Tap result to open Food Detail screen |
| **Recent Tab** | List of recently logged foods sorted by last-used date One-tap re-log with quantity input Food name, last-logged date, calories |
| **My Foods Tab** | User-created custom foods 'Create New Food' button at top List of saved foods with name and kcal Swipe-to-delete |

| AI Scan Result Screen |  |
| :---- | :---- |
| **Purpose** | Display AI-analyzed food data from photo and allow editing before logging |
| **Components** | Food photo at top (full width, rounded corners) Detected food name (editable inline) Detected portion / weight (editable inline, unit selector) Nutrition card: Calories (large), Protein / Carbs / Fat in colored chips Ingredient breakdown list — each ingredient listed with individual calorie/macro contribution (all editable) Accuracy rating: thumbs up / thumbs down (improves model over time) Meal assignment selector: Breakfast / Lunch / Dinner / Snacks Primary CTA: 'Add to Log' Secondary CTA: 'Edit All' (opens manual edit mode) Loading state: spinner with 'Analyzing your meal...' text while AI processes |

| Manual Food Entry Screen |  |
| :---- | :---- |
| **Purpose** | Create or edit a custom food entry |
| **Components** | Food name text field Serving size field \+ unit dropdown (g, oz, ml, cup, tbsp, piece, slice) Number of servings field Calories field (auto-calculated or manual override) Macro fields: Protein / Carbs / Fat (in grams) Expand toggle: micronutrients (Sugar, Fiber, Sodium, Saturated Fat) 'Save to My Foods' checkbox 'Save' primary button |

| Food Detail Screen |  |
| :---- | :---- |
| **Purpose** | Full nutrition facts \+ serving configuration before logging |
| **Components** | Food name \+ brand Serving size selector (size \+ unit) Number of servings input with \+/- stepper Full nutrition panel (FDA label-style layout) Macro donut chart visual Meal assignment selector 'Add to Log' primary button 'Save to My Foods' secondary link |

## **6.4 Exercise Screens**

| Exercise Log Screen |  |
| :---- | :---- |
| **Purpose** | Search and log workouts to offset daily calorie budget |
| **Components** | Search bar: 'Search exercise or activity' Category filter chips: All / Cardio / Strength / Sports / Custom Results list: exercise name, kcal/hour estimate, intensity indicator Recently logged exercises at top Tap result to open Exercise Detail screen |

| Exercise Detail / Add Screen |  |
| :---- | :---- |
| **Purpose** | Configure and log a specific exercise with calorie burn calculation |
| **Components** | Exercise name \+ category icon Duration input (minutes) with \+/- stepper Intensity selector: Light / Moderate / Intense (affects kcal calc) Live estimated calories burned (updates as duration/intensity changes) Notes field (optional) 'Log Exercise' primary button |

## **6.5 Progress & Analytics Screen**

| Progress Screen |  |
| :---- | :---- |
| **Purpose** | Visualize weight trends, goal progress, and nutrition history over time |
| **Components** | Date range selector tabs: Week / Month / 3 Months / 6 Months / All Time Weight line chart with trend line (tappable data points) 'Log Weight' floating action button or inline form BMI card: current value, category label (e.g. 'Normal'), color-coded indicator Goal progress card: '67% toward your goal — X lbs to go' Calorie history bar chart (daily bars, goal line overlay) Weekly macro averages chart (stacked bar or ring) Streak counter: 'X day logging streak' Health Score card (if enabled): composite nutrition quality score Progress Photos section at bottom |
| **Progress Photos** | Chronological grid of timestamped photos 'Add Progress Photo' button Tap photo to view full-screen with date \+ weight overlay Side-by-side comparison view (drag divider between two dates) |

## **6.6 Groups Screen**

| Groups Home Screen |  |
| :---- | :---- |
| **Purpose** | Discover and manage accountability groups |
| **Components** | Tabs: My Groups / Discover My Groups: list with group name, member count, most-recent-activity timestamp Discover: search bar, public group cards (name, member count, category tag, Join button) 'Create Group' button (top-right) Invite friend shortcut |

| Group Detail Screen |  |
| :---- | :---- |
| **Purpose** | Activity feed and community hub for a single group |
| **Components** | Group cover image, name, member count Activity feed: member posts (avatar, name, food photo, calories, timestamp) Reaction / comment buttons on each post Members panel (horizontal avatar row, 'See All' link) Group streak / leaderboard widget 'Share a Meal' CTA (sticky at bottom) Settings icon (group admin only): manage members, privacy, delete |

| Create / Join Group Screen |  |
| :---- | :---- |
| **Purpose** | Create a new group or configure settings when joining |
| **Components** | Group name text input Group photo upload Privacy toggle: Public / Private Description / bio field Invite friends section: contact picker or share link 'Create Group' primary CTA |

## **6.7 Profile & Settings Screens**

| Profile Screen |  |
| :---- | :---- |
| **Purpose** | Personal overview and navigation to account settings |
| **Components** | Profile avatar (tap to change photo) Display name \+ email Stats summary: current weight, goal weight, daily calorie target Streak badge Quick-link cards: My Plan | My Foods | Progress Photos | Referrals 'Edit Profile' button |

| Settings Screen |  |
| :---- | :---- |
| **Purpose** | Centralized app configuration and account management |
| **Account** | Name, Email, Password (each tappable to edit) Sign Out button (with confirmation prompt) |
| **Plan & Goals** | Daily calorie target (editable) Macro split (editable: grams or % toggle) Goal weight, activity level, diet preference 'Recalculate My Plan' shortcut |
| **Subscription** | Current plan badge (Free / Monthly / Yearly) Upgrade / Manage Subscription button Family Plan section (invite up to 5 members, view status) |
| **Preferences** | Units: lbs/kg toggle, ft\&in/cm toggle Dark Mode toggle Language selector Meal reminder times (per meal slot) Logging streak reminder toggle Weekly summary notification toggle |
| **Integrations** | Apple Health / Google Fit sync toggle Apple Watch companion link Google Fit permissions status |
| **Referral Program** | Banner: 'Invite friends, earn cash' Unique referral link with copy button Share sheet trigger Earnings tracker: 'X friends joined · $Y earned' |
| **Support & Legal** | Contact Support (mailto or in-app chat) FAQ link Privacy Policy Terms of Use App version number |

| Edit Goals / Plan Screen |  |
| :---- | :---- |
| **Purpose** | Let user manually override AI-generated nutrition targets |
| **Components** | Daily calorie target (numeric input with up/down stepper) Macro targets: protein / carbs / fat (toggle between grams and % split) Goal weight field Activity level selector (5 options) 'Recalculate with AI' button (re-runs plan gen from current stats) 'Save Changes' primary CTA |

| Notification Settings Screen |  |
| :---- | :---- |
| **Purpose** | Granular control over all push notification types |
| **Components** | Master notifications toggle Per-meal reminder toggles: Breakfast / Lunch / Dinner / Snacks (each with time picker) Meal reminders auto-clear after logging toggle Logging streak reminder toggle Weekly summary toggle Group activity notifications toggle |

| Paywall / Upgrade Screen |  |
| :---- | :---- |
| **Purpose** | Convert free users to paid subscribers (also surfaced in-app after trial) |
| **Components** | Headline: 'Unlock full access' Feature checklist: AI photo scanning, unlimited logging, macro tracking, progress analytics, groups, dark mode Trial timeline graphic: 'Today — Day 3 Reminder — Day 4 Billing Starts' Plan selector: Monthly ($X/mo) vs Yearly (highlighted, shown as lower $/mo) Yearly plan 'Best Value' badge \+ savings callout 'Start 3-Day Free Trial' primary CTA Restore Purchase link Privacy Policy \+ Terms of Use footer links No credit card copy if applicable |

# **7\. Technical Specifications**

## **7.1 AI Food Recognition**

* Primary model: Custom fine-tuned vision transformer trained on 500K+ food images

* Fallback: GPT-4o Vision API for unrecognized or complex dishes

* Portion estimation: uses iPhone LiDAR depth sensor data on supported devices

* Target accuracy: \>90% calorie estimate within ±15% of actual value

* Target latency: \<5 seconds from photo capture to logged result

* User feedback loop: thumbs up/down on each scan improves model over time

## **7.2 Food Database**

* Initial dataset: USDA FoodData Central \+ Open Food Facts (1M+ items)

* Barcode lookups via Open Food Facts API \+ fallback to manual entry

* User-generated custom foods stored per account

* Frequently-logged foods cached locally on-device for offline access

## **7.3 Personalization Engine**

* Calorie target: calculated using Mifflin-St Jeor BMR formula × activity multiplier

* Macro split: defaults tuned per goal (e.g., high protein for muscle gain)

* All AI-generated values are editable by the user at any time

* Plan recalculation available on-demand from Settings

## **7.4 Integrations**

| Apple Health | Read/write steps, active energy, body weight, dietary macros |
| :---- | :---- |
| **Google Fit / Health Connect** | Read/write fitness data, body metrics |
| **Apple Watch** | Log food, check daily totals via watchOS companion app |
| **Wear OS** | Basic macro and calorie widget |
| **iOS Home Screen Widgets** | Calories remaining, macro progress, streak count |
| **Android Widgets** | Same as iOS home screen widgets |

# **8\. Monetization Strategy**

## **8.1 Subscription Plans**

|  | Monthly Plan | Yearly Plan (Best Value) |
| :---- | ----- | ----- |
| **3-Day Free Trial** | Included | Included |
| Price | $4.99/mo | **$2.49/mo (billed $29.99/yr)** |
| AI Photo Scanning | ✓ | ✓ |
| Unlimited Logging | ✓ | ✓ |
| Macro Tracking | ✓ | ✓ |
| Progress Analytics | ✓ | ✓ |
| Groups & Social | ✓ | ✓ |
| Dark Mode | ✓ | ✓ |
| Family Plan Add-on | Available | Available |

## **8.2 Paywall Strategy**

* Hard paywall at end of onboarding — core AI features are gated

* 3-day free trial with no credit card friction at initial install (where platform allows)

* Trial timeline graphic shown on paywall to reduce anxiety about billing

* Yearly plan highlighted as default selection with 'Save 50%' badge

* In-app upgrade prompt triggered when free-tier user attempts gated feature

* Family Plan available as add-on for subscribers (up to 5 family members)

## **8.3 Growth Loops**

* Referral program: subscribers earn cash reward per converted referral

* Groups feature drives organic word-of-mouth through social meal sharing

* Progress photo sharing to Instagram / social drives viral exposure

* App Store ratings prompt timed after user hits first milestone (e.g., 5-day streak)

# **9\. UX Design Principles**

| Core Design Pillars 1\.  Speed first — every core action (photo log, barcode scan, re-log) must complete in under 5 seconds. 2\.  Editable AI — the AI generates suggestions; the user always has final control. 3\.  Visible progress — users should see their progress everywhere, every day. 4\.  Minimal friction — reduce form fields, taps, and decisions wherever possible. 5\.  Dark mode native — ship dark mode on day 1; it is not an afterthought. |
| :---- |

* Color system: primary green (\#1B8A5A), accent orange (\#F4A620), dark navy (\#1A1A2E)

* Typography: system font (SF Pro on iOS, Roboto on Android) for body; Inter or similar for numerics

* Iconography: filled icons for active tab states, outline for inactive

* Animations: subtle spring transitions on modals; calorie ring animates fill on log

* Accessibility: minimum 44pt touch targets, WCAG AA contrast, VoiceOver / TalkBack support

# **10\. Analytics & Success Metrics**

## **10.1 North Star Metrics**

| North Star | Daily Active Users (DAU) who log at least one meal |
| :---- | :---- |
| **Revenue** | Monthly Recurring Revenue (MRR) |
| **Retention** | Day 7 and Day 30 retention rates |
| **Activation** | % of onboarding completions that start free trial |
| **Conversion** | Trial-to-paid conversion rate |

## **10.2 Funnel KPIs**

* App install → onboarding start rate: target \>85%

* Onboarding start → paywall reach: target \>70%

* Paywall → trial start: target \>40%

* Trial → paid conversion: target \>30%

* Day 1 retention: target \>60%

* Day 7 retention: target \>35%

* Day 30 retention: target \>20%

## **10.3 Feature Adoption Targets**

* AI photo scan used at least once: \>80% of active subscribers within first 7 days

* Barcode scan used: \>50% of users within 14 days

* Exercise logged: \>40% of users within 30 days

* Weight logged at least once: \>60% of users within 7 days

* Group joined or created: \>25% of users within 30 days

# **11\. Release Roadmap**

| Sprint | Timeline | Deliverables |
| :---- | :---- | :---- |
| **S1** | Weeks 1–6 | Onboarding flow (25 steps), Auth screens, AI photo scan, Dashboard, Paywall, Barcode scanner, Food DB search, Hard paywall / free trial billing |
| **S2** | Weeks 7–10 | Manual food entry, Custom foods, Exercise logging, Progress/analytics screen, Weight logging, Apple Health / Google Fit sync, Settings & profile |
| **S3** | Weeks 11–14 | Groups (create, join, feed), Progress photos, Referral program, Family plan, Notification settings, Dark mode polish, Beta TestFlight / Play Console |
| **S4** | Weeks 15–18 | Apple Watch app, Android widgets, iOS home screen widgets, Rollover calories, Performance optimization, App Store / Play Store submission |
| **Post-Launch** | Q4 2026+ | AI nutrition coach chat, Restaurant menu photo scan, Public groups discovery, Expanded language support, AI model retraining on user feedback |

# **12\. Risks & Mitigations**

| Risk | Severity | Mitigation |
| :---- | ----- | :---- |
| AI scan accuracy below user expectations | **High** | Set realistic expectations in onboarding; allow full editing of AI results; collect feedback to improve model |
| Long onboarding causes drop-off | **High** | A/B test onboarding length; track per-step abandonment; make all steps feel fast and purposeful |
| App Store / Play Store rejection (hard paywall) | **Medium** | Ensure paywall complies with Apple & Google IAP guidelines; provide restore purchase option |
| Food database gaps for international cuisines | **Medium** | Start with USDA \+ Open Food Facts; allow manual entry; prioritize gap-filling based on user location data |
| User data privacy regulations (GDPR, CCPA) | **Medium** | Build data deletion flow; document data handling; appoint DPO; ship privacy center in settings |
| Competitive pressure from MyFitnessPal, Cronometer | **Medium** | Differentiate on speed and AI-first UX; invest heavily in photo scan accuracy |

# **13\. Appendix**

## **A. Glossary**

| TDEE | Total Daily Energy Expenditure — total calories burned per day |
| :---- | :---- |
| **BMR** | Basal Metabolic Rate — calories burned at complete rest |
| **Macro** | Macronutrient: protein, carbohydrates, or fat |
| **Hard Paywall** | Users cannot access core features without starting a paid trial |
| **Soft Paywall** | Core features accessible for free; premium features gated |
| **MRR** | Monthly Recurring Revenue |
| **DAU** | Daily Active Users |
| **LiDAR** | Apple depth sensor used for more accurate portion volume estimation |

## **B. Out of Scope (v1.0)**

* Web application (mobile only at launch)

* Meal planning / recipe suggestions (post-launch)

* Restaurant menu integration (post-launch)

* AI nutrition coach chat (post-launch)

* Paid advertising or sponsored food content

* Medical or clinical dietary advice features

## **C. Open Questions**

26. Should we gate Groups behind the paywall or offer it in free tier to drive social virality?

27. What is the correct price point for the Family Plan add-on?

28. Do we offer a lifetime purchase option in addition to subscriptions?

29. Should Rollover Calories be automatic or opt-in?

30. What is the minimum viable onboarding we can ship if S1 timeline is at risk?

*GojoCalories — Product Requirements Document v1.0*

*Confidential & Proprietary. For internal use only.*