# ComplyHealth Marketing Website - Development Plan

## Project Overview
Static SvelteKit website for ComplyHealth beta launch. Clean, approachable design focused on medication management empowerment.

## Tech Stack
- SvelteKit (static adapter)
- Firebase SDK (for beta signup form)
- Deployment: Vercel (recommended) or Netlify/Cloudflare Pages

## Site Structure

### 1. Hero Section
**H2 Heading:**
"Meds under control. Finally."

**Body Copy:**
You're juggling enough already. Built by a nurse who gets it, ComplyHealth takes the mental load off medication management so you can focus on what matters - your health and your life.

**CTA Button:**
"Join the Beta"
- Smooth scroll to signup form section

### 2. Features Section
Three feature cards with icon + heading + description:

**Feature 1: Simple Tracking**
Add your medications, see your schedule at a glance. No complexity, no confusion.

**Feature 2: Smart Reminders**
Get notified when it's time to take your meds. Never wonder "did I take that?" again.

**Feature 3: Understand Your Health**
Learn about the conditions you're managing and how your medications help. Knowledge is power.

### 3. Beta Signup Section
**Form Fields:**
- Name (text input, required)
- Email (email input, required)
- Platform preference (radio buttons: iOS / Android / Both, required)
- Optional: "Tell us about your medication management challenges" (textarea, optional)

**Submission:**
- Write to Firebase Firestore collection: `beta_signups`
- Document structure:
```javascript
  {
    name: string,
    email: string,
    platform: string, // "iOS" | "Android" | "Both"
    challenges: string, // optional
    timestamp: Firestore.Timestamp,
    status: "pending" // for future filtering
  }
```
- Success message: "Thanks for signing up! We'll be in touch soon with beta access."
- Error handling for failed submissions

### 4. Footer
- Copyright: © 2024 ComplyHealth
- Optional links: Privacy Policy, Contact
- Keep minimal for beta

## Design Guidelines
- **Tone:** Empowering and approachable
- **Colors:** Clean, medical-appropriate palette (suggest blues/teals for trust, with warm accent)
- **Typography:** Clear, readable fonts - nothing too clinical or too playful
- **Spacing:** Generous whitespace, not cramped
- **Mobile-first:** Fully responsive design
- **Accessibility:** Proper semantic HTML, ARIA labels where needed

## Firebase Setup Required
1. Initialize Firebase in the SvelteKit project
2. Configure Firestore with `beta_signups` collection
3. Set up appropriate security rules for writes
4. Add Firebase config to environment variables

## Deployment
- Use `@sveltejs/adapter-static` for static site generation
- Deploy to Vercel with GitHub integration
- Configure custom domain when ready
- Set up environment variables for Firebase config

## Future Considerations (Post-Beta)
- Add testimonials section once beta users provide feedback
- Expand with "How It Works" walkthrough
- Add screenshots/mockups of app interface
- Consider adding FAQ section
- Analytics integration (Google Analytics or Plausible)

## Development Checklist
- [ ] Initialize SvelteKit project with static adapter
- [ ] Set up Firebase SDK and Firestore connection
- [ ] Build hero section component
- [ ] Build features section with 3 cards
- [ ] Build beta signup form with Firebase integration
- [ ] Build footer component
- [ ] Implement responsive design (mobile, tablet, desktop)
- [ ] Add smooth scroll behavior for CTA button
- [ ] Test form submission and Firestore writes
- [ ] Add loading states and error handling to form
- [ ] Verify accessibility (keyboard navigation, screen readers)
- [ ] Test on multiple devices/browsers
- [ ] Set up Vercel deployment
- [ ] Configure environment variables in Vercel
- [ ] Test production deployment

## Notes
- Keep it simple - this is a beta landing page, not a full marketing site
- Focus on clear messaging over fancy animations
- Prioritize fast load times and mobile experience
- The nurse credibility angle is key - don't bury it
- Form should be frictionless - minimize required fields
