## **gojocalories**

## **ONBOARDING FLOW (25 steps — no account created yet)**

### **1\. Splash / Welcome Screen**

* App logo centered on dark background  
* Tagline: "Track your calories with just a picture"  
* Single CTA button: "Get Started"  
* Social proof badge: "Loved by 5M users · ⭐ 4.9"

### **2\. Social Proof / Testimonial Screen**

* Animated progress graph showing weight loss over time  
* Before/after stat overlay (e.g. "91% of users reach their goal")  
* Influencer/user quote carousel  
* "Continue" button

### **3\. Goal Selection Screen**

* Headline: "What's your main goal?"  
* Selectable card options: Lose Weight / Maintain Weight / Gain Muscle  
* Single-select with icon per option  
* Progress bar at top (step indicator)

### **4\. Gender Selection Screen**

* Headline: "What's your biological sex?"  
* Two large tappable cards: Male / Female  
* Progress bar

### **5\. Current Weight Input Screen**

* Headline: "What's your current weight?"  
* Number scroll picker (lbs / kg toggle)  
* Progress bar

### **6\. Target Weight Input Screen**

* Headline: "What's your target weight?"  
* Number scroll picker  
* Progress bar

### **7\. Goal Validation / Realism Screen *(key conversion screen)***

* Shows user's stated goal (e.g. "Lose 20 lbs")  
* Badge/label: "This goal is realistic ✅"  
* Short motivational copy  
* "Continue" CTA

### **8\. Height Input Screen**

* Headline: "How tall are you?"  
* Number scroll picker (ft/in or cm toggle)  
* Progress bar

### **9\. Age / Date of Birth Screen**

* Headline: "How old are you?"  
* Number scroll picker or date input  
* Progress bar

### **10\. Activity Level Screen**

* Headline: "How active are you?"  
* 4–5 selectable card options: Sedentary / Lightly Active / Moderately Active / Very Active / Athlete  
* Icon \+ label \+ short description per card

### **11\. Diet / Eating Preference Screen**

* Headline: "Do you follow any specific diet?"  
* Multi-select cards: None / Keto / Vegan / Vegetarian / Intermittent Fasting / High-Protein / Gluten-Free  
* "Skip" option

### **12\. Workout Frequency Screen**

* Headline: "How often do you work out?"  
* Selectable options: Never / 1–2x week / 3–4x week / 5+ times/week

### **13\. Biggest Challenge Screen**

* Headline: "What's your biggest challenge?"  
* Multi-select cards: Portion control / Eating out / Snacking / Consistency / Knowing what to eat

### **14\. Meal Inspiration / Notification Opt-in Screen**

* Headline: "Want meal reminders?"  
* Short copy about staying on track  
* "Allow Notifications" primary button  
* "Not now" secondary link

### **15\. Projected Results / Plan Preview Screen**

* Animated weight-loss graph showing projected timeline  
* Projected goal date displayed prominently  
* Comparison: "Without Cal AI" vs "With Cal AI" curves  
* "This looks great\!" CTA

### **16\. AI Plan Generation Screen *(loading/processing screen)***

* Animated loader/spinner  
* Text cycling through: "Analyzing your data…", "Building your plan…"  
* Progress bar or dots

### **17\. Personalized Plan Summary Screen *(editable)***

* Headline: "Your personalized plan is ready"  
* Daily calorie target (large number, editable)  
* Macro breakdown: Protein / Carbs / Fat (editable)  
* TDEE explanation  
* "Looks good" CTA

### **18\. Paywall / Free Trial Screen *(hard paywall)***

* Headline: "Start your 3-day free trial"  
* Trial timeline graphic: Today → Day 3 reminder → Day 4 billing starts  
* Two plan options: Monthly ($X/mo) vs Yearly (highlighted, shown as $/mo equivalent)  
* Feature checklist: AI scanning, unlimited logging, macro tracking, etc.  
* "Start Free Trial" primary CTA  
* Restore purchase / Terms links at bottom

---

## **🟢 AUTHENTICATION FLOW**

### **19\. Sign Up Screen**

* Headline: "Create your account"  
* Email input field  
* Password input field  
* "Sign Up" button  
* Divider: "or"  
* Sign in with Apple button  
* Sign in with Google button  
* "Already have an account? Log in" link

### **20\. Log In Screen**

* Email \+ password fields  
* "Forgot Password?" link  
* "Log In" button  
* Social sign-in buttons (Apple / Google)  
* "Don't have an account? Sign Up" link

### **21\. Forgot Password Screen**

* Email input field  
* "Send Reset Link" button  
* Back link

---

## **🟡 MAIN APP SCREENS (Bottom Nav: Home · Log · Progress · Groups · Profile)**

### **22\. Home / Dashboard Screen *(main screen)***

* Top bar: greeting ("Good morning, \[Name\]"), settings icon  
* Large calorie ring/donut chart: "Calories Remaining" in center  
* 3 macro bars below ring: Protein / Carbs / Fat (grams consumed vs goal)  
* Water intake tracker (quick-add buttons: \+250ml)  
* Meal sections: Breakfast / Lunch / Dinner / Snacks (each collapsible)  
  * Each meal shows logged items with calorie count \+ quick-delete  
  * "+ Add food" row per meal  
* Exercise section: logged workouts \+ calories burned offset  
* Streak counter / daily goal badge  
* Home screen widget support (calories \+ macros at a glance)

### **23\. Food Log / Add Food Screen *(triggered from "+" or camera)***

* Top tab bar: Camera · Barcode · Search · Recent · My Foods  
* **Camera tab:** full-screen camera viewfinder, shutter button, flip camera icon, tip overlay ("Hold over your meal")  
* **Barcode tab:** scan frame overlay, torch toggle  
* **Search tab:** search bar, results list (food name, brand, calories per serving), filter/sort  
* **Recent tab:** list of recently logged foods (name \+ calories), quick re-log tap  
* **My Foods tab:** custom saved foods, "Create new food" button

### **24\. AI Food Analysis / Scan Result Screen**

* Food photo displayed at top  
* Detected food name (editable)  
* Detected portion/weight (editable)  
* Macro breakdown card: Calories / Protein / Carbs / Fat  
* Ingredient breakdown list (each ingredient editable)  
* Thumbs up / thumbs down accuracy rating buttons  
* Meal assignment selector: Breakfast / Lunch / Dinner / Snacks  
* "Add to Log" primary button  
* "Edit" secondary button

### **25\. Manual Food Entry / Edit Food Screen**

* Food name field (editable)  
* Serving size \+ unit selector (g / oz / ml / cup / piece)  
* Calorie input field  
* Macro fields: Protein / Carbs / Fat  
* Micronutrients toggle (Sugar / Sodium / Fiber / Saturated Fat)  
* "Save" button  
* Option: "Save to My Foods"

### **26\. Food Detail Screen *(from search result tap)***

* Full nutrition facts panel (FDA-style label layout)  
* Serving size selector  
* Number of servings input  
* Macro rings / bars  
* Meal selector  
* "Add to Log" button

### **27\. Exercise Log Screen *(from Home or Log tab)***

* Search bar: "Search exercise"  
* Exercise categories: Cardio / Strength / Sports / Custom  
* Results list with calories burned estimate  
* Quick-log: duration \+ intensity inputs  
* "Add Exercise" button

### **28\. Exercise Detail / Add Screen**

* Exercise name  
* Duration input (minutes)  
* Intensity selector (Light / Moderate / Intense)  
* Estimated calories burned (live update)  
* "Log Exercise" button

---

## **🔴 PROGRESS / ANALYTICS SCREEN**

### **29\. Progress Screen**

* Top date range selector: Week / Month / 3M / 6M / All  
* Weight graph (line chart with trend line)  
* "Log Weight" button / inline weight entry  
* BMI card with current BMI \+ category label  
* Goal achievement % card ("You're 67% toward your goal")  
* Macro history bar charts (weekly averages)  
* Calorie streak counter  
* Progress Photos section: grid of timestamped photos, "Add Photo" button

### **30\. Progress Photo Detail Screen**

* Full-screen photo view  
* Date \+ weight at that date overlay  
* Swipe to compare side-by-side (before/after)  
* Delete / Share options

---

## **🟣 GROUPS SCREEN**

### **31\. Groups Home Screen**

* Top tabs: My Groups / Discover  
* List of joined groups (group name, member count, recent activity)  
* "Create Group" button  
* "Find Groups" / search bar

### **32\. Group Detail Screen**

* Group name, cover image, member count  
* Recent meal posts feed (member name, food photo, calories)  
* Members list section  
* "Share a Meal" CTA button  
* Group streak / leaderboard widget

### **33\. Create / Join Group Screen**

* Group name input  
* Privacy toggle: Public / Private  
* Invite friends section (contact picker)  
* "Create Group" button

---

## **⚙️ PROFILE / SETTINGS SCREEN**

### **34\. Profile Screen**

* Avatar / profile photo  
* Display name \+ email  
* Current stats summary: weight, goal, daily calorie target  
* "Edit Profile" button  
* Quick links: My Plan, My Foods, Progress Photos

### **35\. Settings Screen *(redesigned, organized)***

* **Account section:** Name, Email, Password, Sign Out  
* **Plan & Goals section:** Daily calorie target, Macro targets, Goal weight, Activity level (all editable)  
* **Subscription section:** Current plan badge, Upgrade / Manage Subscription, Family Plan (up to 5 members)  
* **Preferences section:** Units (lbs/kg, ft/cm), Dark Mode toggle, Notifications settings, Meal reminder times  
* **Integrations section:** Apple Health / Google Fit sync toggle, Apple Watch  
* **Referral Program section:** "Invite friends, earn cash" banner, referral link / share button  
* **Support section:** Contact support, FAQ, Privacy Policy, Terms of Use  
* **App version** at bottom

### **36\. Edit Goals / Plan Screen**

* Daily calorie target (number input)  
* Protein / Carbs / Fat targets (grams or % split, togglable)  
* Goal weight input  
* Activity level selector  
* "Save Changes" button

### **37\. Notification Settings Screen**

* Master notification toggle  
* Meal reminder toggles per meal: Breakfast / Lunch / Dinner / Snacks  
* Time picker per reminder  
* "Logging streak" reminder toggle  
* "Weekly summary" toggle

### **38\. My Foods Screen**

* Search bar  
* List of user-created custom foods (name, calories, macros)  
* "Create New Food" button  
* Swipe-to-delete on each item

### **39\. Referral / Invite Screen**

* Headline: "Invite friends, earn cash"  
* Unique referral link with copy button  
* Share via: Messages, WhatsApp, Instagram, etc.  
* Earnings tracker: "X friends joined · $Y earned"

---

## **💳 PAYWALL / UPGRADE SCREEN *(accessible in-app)***

### **40\. Upgrade / Subscription Screen**

* Feature comparison: Free vs Premium  
* Plan selector: Monthly / Yearly (yearly highlighted as best value)  
* Trial timeline graphic  
* "Start Free Trial" CTA  
* "Restore Purchase" link

### **41\. Family Plan Screen**

* Headline: "Share with your family"  
* Up to 5 members  
* Invite by email input  
* Current members list with status (Accepted / Pending)  
* Price breakdown

---

**Total: \~41 distinct screens across 7 flows.**

