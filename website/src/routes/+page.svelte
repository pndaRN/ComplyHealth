<script>
  import { getDb, collection, addDoc, serverTimestamp } from "$lib/firebase.js";
  import { validateEmail, errorMessages } from "$lib/emailValidation.js";
  import SurveyModal from "$lib/components/SurveyModal.svelte";
  import {
    initAnalytics,
    trackEmailValidationStart,
    trackEmailValidationSuccess,
    trackEmailValidationFailure,
    trackSurveyStarted,
    trackPageView,
    trackFormSubmission,
    trackError
  } from "$lib/analytics.js";

  let email = $state("");
  let isSubmitting = $state(false);
  let submitStatus = $state(""); // 'success' | 'error' | ''
  let errorMessage = $state("");
  let showSurveyModal = $state(false);
  let loadingStep = $state(0);
  let validationStartTime = $state(0);
  let submittedEmail = $state("");

  const loadingMessages = [
    "Checking email format...",
    "Verifying email domain...",
    "Almost done..."
  ];



  // Initialize analytics on component mount
  $effect(() => {
    initAnalytics();
    trackPageView('landing_page');
  });

  async function handleSubmit(event) {
    event.preventDefault();
    console.log("Form submitted with email:", email);

    if (!email || !email.includes("@")) {
      console.log("Email validation failed");
      errorMessage = "Please enter a valid email address";
      submitStatus = "error";
      return;
    }

    console.log("Starting submission process");
    isSubmitting = true;
    submitStatus = "";
    errorMessage = "";
    loadingStep = 0;
    validationStartTime = Date.now();

    // Track validation start
    trackEmailValidationStart(email);
    console.log("Calling validateEmail");

    // Update loading message every 2 seconds
    const loadingInterval = setInterval(() => {
      if (loadingStep < loadingMessages.length - 1) {
        loadingStep++;
      }
    }, 2000);

    try {
      const validation = await validateEmail(email);
      console.log("Validation result:", validation);
      clearInterval(loadingInterval);

      if (validation.valid) {
        console.log("Email valid, saving to Firebase");
        // Success flow
        trackEmailValidationSuccess(email, validation.validationTime);
        
        const db = getDb();
        await addDoc(collection(db, "mission_supporters"), {
          email,
          timestamp: serverTimestamp(),
          status: "new",
          source: "landing_page_phase3",
          validation_details: {
            domain_valid: validation.details?.valid || false,
            is_disposable: validation.details?.disposable || false,
            validation_timestamp: serverTimestamp(),
            validation_time: validation.validationTime || 0
          }
        });
        console.log("Saved to Firebase successfully");

        trackFormSubmission(email, 'landing_page_phase3');

        submitStatus = "success";
        submittedEmail = email;
        email = "";

        // Show survey modal after short delay
        setTimeout(() => {
          showSurveyModal = true;
          trackSurveyStarted(submittedEmail);
        }, 1000);
      } else {
        console.log("Email invalid:", validation.reason);
        // Error flow with retry option
        trackEmailValidationFailure(email, validation.reason);
        errorMessage = errorMessages[validation.reason];
        submitStatus = "error";
      }
    } catch (error) {
      clearInterval(loadingInterval);
      console.error("Error submitting form:", error);
      trackError(error, 'email_validation');
      submitStatus = "error";
      errorMessage = "Something went wrong. Please try again.";
    } finally {
      isSubmitting = false;
      loadingStep = 0;
      validationStartTime = 0;
    }
  }

  function scrollToSignup() {
    document.getElementById("signup")?.scrollIntoView({ behavior: "smooth" });
  }

  function handleSurveyClosed() {
    showSurveyModal = false;
    submittedEmail = "";
  }

  function getLoadingMessage() {
    return loadingMessages[loadingStep] || loadingMessages[loadingMessages.length - 1];
  }
</script>

<main class="min-h-screen">
  <!-- Header -->
  <header class="px-4 py-3">
    <!-- Light mode logo -->
    <img src="/complyhealth-logo.svg" alt="ComplyHealth" class="h-10 dark:hidden" />
    <!-- Dark mode logo -->
    <img src="/complyhealth-logo-dark.svg" alt="ComplyHealth" class="h-10 hidden dark:block" />
  </header>

  <!-- Hero Section -->
  <section class="px-4 py-12 md:py-20 max-w-4xl mx-auto text-center">
    <h1
      class="text-4xl md:text-5xl lg:text-6xl font-semibold text-text-primary mb-6"
    >
      Chronic health shouldn't be overwhelming
    </h1>
    <p
      class="text-lg md:text-xl text-text-secondary max-w-2xl mx-auto mb-10 leading-relaxed"
    >
      We're healthcare professionals building a simple way to track meds and conditions, all in one simple place - without juggling portals or paperwork.
    </p>
    <button
      onclick={scrollToSignup}
      class="bg-primary hover:bg-primary/90 text-white font-medium px-8 py-4 rounded-lg text-lg transition-colors cursor-pointer shadow-lg hover:shadow-xl"
    >
      Join Our Mission
    </button>
  </section>

  <!-- Before/After Section -->
   <section class="px-4 py-12 md:py-20">
    <div class="max-w-6xl mx-auto">
      <h2 class="text-3xl md:text-4xl font-semibold text-text-primary text-center mb-12">
        From Chaos to Clarity
      </h2>
      <div class="grid md:grid-cols-2 gap-8 md:gap-12">
        <div class="bg-background p-6 rounded-xl shadow-lg border border-outline">
          <h3 class="text-xl font-semibold text-text-primary mb-6 text-center">Before</h3>
          <ul class="space-y-4">
            <li class="flex items-start gap-3">
              <div class="w-2 h-2 bg-error rounded-full mt-2 flex-shrink-0"></div>
              <span class="text-text-secondary">Cluttered instructions</span>
            </li>
            <li class="flex items-start gap-3">
              <div class="w-2 h-2 bg-error rounded-full mt-2 flex-shrink-0"></div>
              <span class="text-text-secondary">Unorganized information</span>
            </li>
            <li class="flex items-start gap-3">
              <div class="w-2 h-2 bg-error rounded-full mt-2 flex-shrink-0"></div>
              <span class="text-text-secondary">Miscommunication</span>
            </li>
            <li class="flex items-start gap-3">
              <div class="w-2 h-2 bg-error rounded-full mt-2 flex-shrink-0"></div>
              <span class="text-text-secondary">Missed medications</span>
            </li>
          </ul>
        </div>
        <div class="bg-background p-6 rounded-xl shadow-lg border border-outline">
          <h3 class="text-xl font-semibold text-text-primary mb-6 text-center">After</h3>
          <ul class="space-y-4">
            <li class="flex items-start gap-3">
              <div class="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0"></div>
              <span class="text-text-secondary">Clear health organization</span>
            </li>
            <li class="flex items-start gap-3">
              <div class="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0"></div>
              <span class="text-text-secondary">Reduced stress</span>
            </li>
            <li class="flex items-start gap-3">
              <div class="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0"></div>
              <span class="text-text-secondary">Promotes medication compliance</span>
            </li>
            <li class="flex items-start gap-3">
              <div class="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0"></div>
              <span class="text-text-secondary">Fewer missed appointments</span>
            </li>
            <li class="flex items-start gap-3">
              <div class="w-2 h-2 bg-primary rounded-full mt-2 flex-shrink-0"></div>
              <span class="text-text-secondary">Better understanding</span>
            </li>
          </ul>
        </div>
      </div>
     </div>

     <!-- Gradient Separator -->
     <div class="h-12 bg-gradient-to-b from-white/30 to-surface/30"></div>
   </section>

   <!-- Problem Section -->
  <section class="scroll-section px-4 py-12 md:py-20 bg-surface">
    <div class="max-w-4xl mx-auto">
      <div class="text-center mb-12">
        <h2 class="text-3xl md:text-4xl font-semibold text-text-primary mb-6">
          The Daily Struggle is Real
        </h2>
        <p class="text-lg text-text-secondary leading-relaxed max-w-2xl mx-auto mb-8">
          Millions of adults manage chronic conditions, often feeling:
        </p>
      </div>

      <div class="grid gap-6 md:grid-cols-2">
        <div class="bg-background p-6 rounded-lg shadow-sm border border-outline">
          <div class="flex items-start gap-3">
            <div class="w-3 h-3 bg-error rounded-full mt-2 flex-shrink-0"></div>
            <p class="text-text-secondary text-base leading-relaxed">
              Fragmented information across apps, paper notes, and memory
            </p>
          </div>
        </div>
        <div class="bg-background p-6 rounded-lg shadow-sm border border-outline">
          <div class="flex items-start gap-3">
            <div class="w-3 h-3 bg-error rounded-full mt-2 flex-shrink-0"></div>
            <p class="text-text-secondary text-base leading-relaxed">
              Confused by medical terminology and treatment plans
            </p>
          </div>
        </div>
        <div class="bg-background p-6 rounded-lg shadow-sm border border-outline">
          <div class="flex items-start gap-3">
            <div class="w-3 h-3 bg-error rounded-full mt-2 flex-shrink-0"></div>
            <p class="text-text-secondary text-base leading-relaxed">
              Worried about forgetting medications or instructions
            </p>
          </div>
        </div>
        <div class="bg-background p-6 rounded-lg shadow-sm border border-outline">
          <div class="flex items-start gap-3">
            <div class="w-3 h-3 bg-error rounded-full mt-2 flex-shrink-0"></div>
            <p class="text-text-secondary text-base leading-relaxed">
              Emotional frustration and exhaustion from it all
            </p>
          </div>
        </div>
      </div>

      <div class="mt-12 text-center">
        <p class="text-lg text-text-primary font-medium max-w-3xl mx-auto">
          As healthcare professionals, we've seen this struggle firsthand. That's why we're building something different.
        </p>
      </div>
    </div>

    <!-- Gradient Separator -->
    <div class="h-12 bg-gradient-to-b from-surface/30 to-white/30"></div>
  </section>

  <!-- Solution Section -->
  <section class="scroll-section px-4 py-12 md:py-20">
    <div class="max-w-4xl mx-auto">
      <div class="text-center mb-12">
        <h2 class="text-3xl md:text-4xl font-semibold text-text-primary mb-6">
          What if it could be simpler?
        </h2>
        <p class="text-lg text-text-secondary leading-relaxed max-w-2xl mx-auto mb-8">
          ComplyHealth brings structure and clarity to everyday health management by:
        </p>
      </div>

      <div class="grid gap-6 md:grid-cols-2">
        <div class="bg-background p-6 rounded-lg shadow-sm border border-outline">
          <div class="flex items-start gap-3">
            <div class="w-3 h-3 bg-primary rounded-full mt-2 flex-shrink-0"></div>
            <p class="text-text-secondary text-base leading-relaxed">
              <strong>Centralizing</strong> your medications and conditions in one place
            </p>
          </div>
        </div>
        <div class="bg-background p-6 rounded-lg shadow-sm border border-outline">
          <div class="flex items-start gap-3">
            <div class="w-3 h-3 bg-primary rounded-full mt-2 flex-shrink-0"></div>
            <p class="text-text-secondary text-base leading-relaxed">
              <strong>Explaining</strong> everything in plain language that makes sense
            </p>
          </div>
        </div>
        <div class="bg-background p-6 rounded-lg shadow-sm border border-outline">
          <div class="flex items-start gap-3">
            <div class="w-3 h-3 bg-primary rounded-full mt-2 flex-shrink-0"></div>
            <p class="text-text-secondary text-base leading-relaxed">
              <strong>Reducing</strong> cognitive burden so you can focus on living
            </p>
          </div>
        </div>
        <div class="bg-background p-6 rounded-lg shadow-sm border border-outline">
          <div class="flex items-start gap-3">
            <div class="w-3 h-3 bg-primary rounded-full mt-2 flex-shrink-0"></div>
            <p class="text-text-secondary text-base leading-relaxed">
              <strong>Helping</strong> you feel more confident and in control
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Gradient Separator -->
    <div class="h-12 bg-gradient-to-b from-white/30 to-surface/30"></div>
  </section>

  <!-- Audience Section -->
  <section class="scroll-section px-4 py-12 md:py-20 bg-surface">
    <div class="max-w-4xl mx-auto">
      <div class="text-center mb-12">
        <h2 class="text-3xl md:text-4xl font-semibold text-text-primary mb-12">
          You're Not Alone in This
        </h2>
      </div>

      <div class="grid gap-8 md:grid-cols-2">
        <div class="bg-background p-8 rounded-lg shadow-sm border border-outline text-center">
          <h3 class="text-xl font-semibold text-text-primary mb-4">
            For Adults Managing Chronic Conditions
          </h3>
          <p class="text-text-secondary text-base leading-relaxed">
            If you're 25-65, managing 2+ chronic conditions and taking multiple medications, and feeling overwhelmed - this is for you.
          </p>
        </div>
        <div class="bg-background p-8 rounded-lg shadow-sm border border-outline text-center">
          <h3 class="text-xl font-semibold text-text-primary mb-4">
            For Caregivers
          </h3>
          <p class="text-text-secondary text-base leading-relaxed">
            If you're helping a loved one navigate their health journey, we want to support you too.
          </p>
        </div>
      </div>
    </div>

    <!-- Gradient Separator -->
    <div class="h-12 bg-gradient-to-b from-surface/30 to-white/30"></div>
  </section>

  <!-- Differentiation Section -->
  <section class="scroll-section px-4 py-12 md:py-20">
    <div class="max-w-4xl mx-auto">
      <div class="text-center mb-12">
        <h2 class="text-3xl md:text-4xl font-semibold text-text-primary mb-12">
          Built Differently Because It Has to Be
        </h2>
      </div>

      <div class="grid gap-6 md:grid-cols-3">
        <div class="bg-background p-6 rounded-lg shadow-sm border border-outline text-center">
          <h3 class="text-lg font-semibold text-text-primary mb-4">
            Healthcare Professional-Founded
          </h3>
          <p class="text-text-secondary text-sm leading-relaxed">
            Built by people with direct patient-care experience who understand the real challenges.
          </p>
        </div>
        <div class="bg-background p-6 rounded-lg shadow-sm border border-outline text-center">
          <h3 class="text-lg font-semibold text-text-primary mb-4">
            Plain Language
          </h3>
          <p class="text-text-secondary text-sm leading-relaxed">
            No confusing medical jargon. Just clear explanations that make sense.
          </p>
        </div>
        <div class="bg-background p-6 rounded-lg shadow-sm border border-outline text-center">
          <h3 class="text-lg font-semibold text-text-primary mb-4">
            Independent
          </h3>
          <p class="text-text-secondary text-sm leading-relaxed">
            Built for people, not for systems. Your confidence over clinical workflows.
          </p>
        </div>
      </div>
    </div>
  </section>

  <!-- Join Mission Section -->
  <section id="signup" class="px-4 py-8 md:py-12">
    <div class="max-w-xl mx-auto text-center">
      <h2 class="text-2xl md:text-3xl font-semibold text-text-primary mb-3">
        Join Our Mission
      </h2>
      <p class="text-text-secondary text-sm mb-6 leading-relaxed">
        We're building this for real people facing real challenges. Your input helps us create the solution you actually need.
      </p>

      {#if submitStatus === "success"}
        <div
          class="bg-tertiary/10 border border-tertiary text-tertiary p-6 rounded-xl text-center"
        >
          <svg
            class="w-12 h-12 mx-auto mb-4"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <p class="font-medium text-lg">Welcome aboard!</p>
          <p class="mt-2 text-tertiary/80">
            Thanks for joining our mission. We'll be in touch with updates as we build what you need.
          </p>
        </div>
      {:else}
        <form onsubmit={(e) => handleSubmit(e)} class="space-y-6">
          {#if submitStatus === "error"}
            <div
              class="bg-error/10 border border-error text-error p-4 rounded-lg"
            >
              {errorMessage}
            </div>
          {/if}

          <div>
            <label
              for="email"
              class="block text-sm font-medium text-text-primary mb-2"
            >
              Email <span class="text-error">*</span>
            </label>
            <input
              type="email"
              id="email"
              bind:value={email}
              required
              class="w-full px-4 py-3 rounded-lg border border-outline bg-background text-text-primary focus:border-primary focus:ring-2 focus:ring-primary/20 transition-colors"
              placeholder="you@example.com"
            />
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            class="w-full bg-primary hover:bg-primary/90 disabled:bg-primary/50 disabled:cursor-not-allowed text-white font-medium py-4 rounded-lg text-lg transition-colors cursor-pointer"
          >
            {#if isSubmitting}
              <span class="flex items-center justify-center gap-2">
                <svg
                  class="animate-spin w-5 h-5"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    class="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                  ></circle>
                  <path
                    class="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  ></path>
                </svg>
                {getLoadingMessage()}
              </span>
            {:else}
              Join Our Mission
            {/if}
          </button>
        </form>
      {/if}
    </div>
  </section>

  <!-- Footer -->
  <footer class="px-4 py-6 border-t border-outline">
    <div class="max-w-6xl mx-auto text-center">
      <p class="text-text-secondary text-sm mb-2">
        &copy; 2025 ComplyHealth. All rights reserved.
      </p>
      <p class="text-text-secondary text-xs">
        ComplyHealth is an independent product and is not affiliated with or endorsed by any healthcare organization.
      </p>
    </div>
  </footer>
</main>

<!-- Survey Modal -->
<SurveyModal
  bind:isOpen={showSurveyModal}
  userEmail={submittedEmail}
/>

<style>
  @keyframes fadeIn {
    from {
      opacity: 0;
    }
    to {
      opacity: 1;
    }
  }

  .scroll-section {
    animation: fadeIn 1s ease-out;
  }
</style>
