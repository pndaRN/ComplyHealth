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
  let activeTab = $state(0);

  const loadingMessages = [
    "Checking email format...",
    "Verifying email domain...",
    "Almost done..."
  ];

  const tabs = [
    {
      title: "The Challenge",
      content: {
        heading: "The Daily Struggle is Real",
        subheading: "Millions of adults manage chronic conditions, often feeling:",
        items: [
          "Fragmented information across apps, paper notes, and memory",
          "Confused by medical terminology and treatment plans",
          "Worried about forgetting medications or instructions",
          "Emotional frustration and exhaustion from it all"
        ],
        footer: "As nurses, we've seen this struggle firsthand. That's why we're building something different."
      }
    },
    {
      title: "Our Solution",
      content: {
        heading: "What if it could be simpler?",
        subheading: "ComplyHealth brings structure and clarity to everyday health management by:",
        items: [
          "Centralizing your medications and conditions in one place",
          "Explaining everything in plain language that makes sense",
          "Reducing cognitive burden so you can focus on living",
          "Helping you feel more confident and in control"
        ]
      }
    },
    {
      title: "Who It's For",
      content: {
        heading: "You're Not Alone in This",
        items: [
          {
            title: "For Adults Managing Chronic Conditions",
            description: "If you're 25-65, managing 2+ chronic conditions and taking multiple medications, and feeling overwhelmed - this is for you."
          },
          {
            title: "For Caregivers",
            description: "If you're helping a loved one navigate their health journey, we want to support you too."
          }
        ]
      }
    },
    {
      title: "Why We're Different",
      content: {
        heading: "Built Differently Because It Has to Be",
        items: [
          {
            title: "Nurse-Founded",
            description: "Built by people with direct patient-care experience who understand the real challenges."
          },
          {
            title: "Plain Language",
            description: "No confusing medical jargon. Just clear explanations that make sense."
          },
          {
            title: "Independent",
            description: "Built for people, not for systems. Your confidence over clinical workflows."
          }
        ]
      }
    }
  ];

  // Initialize analytics on component mount
  $effect(() => {
    initAnalytics();
    trackPageView('landing_page');
  });

  async function handleSubmit(event) {
    event.preventDefault();

    if (!email || !email.includes("@")) {
      errorMessage = "Please enter a valid email address";
      submitStatus = "error";
      return;
    }

    isSubmitting = true;
    submitStatus = "";
    errorMessage = "";
    loadingStep = 0;
    validationStartTime = Date.now();

    // Track validation start
    trackEmailValidationStart(email);

    // Update loading message every 2 seconds
    const loadingInterval = setInterval(() => {
      if (loadingStep < loadingMessages.length - 1) {
        loadingStep++;
      }
    }, 2000);

    try {
      const validation = await validateEmail(email);
      clearInterval(loadingInterval);

      if (validation.valid) {
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

        trackFormSubmission(email, 'landing_page_phase3');

        submitStatus = "success";
        email = "";
        
        // Show survey modal after short delay
        setTimeout(() => {
          showSurveyModal = true;
          trackSurveyStarted(email);
        }, 1000);
      } else {
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
      Managing chronic conditions shouldn't feel overwhelming
    </h1>
    <p
      class="text-lg md:text-xl text-text-secondary max-w-2xl mx-auto mb-10 leading-relaxed"
    >
      We're building a simple way to organize your health information so you can feel more in control. 
      Built by nurses who get it, because we've been there too.
    </p>
    <button
      onclick={scrollToSignup}
      class="bg-primary hover:bg-primary/90 text-white font-medium px-8 py-4 rounded-lg text-lg transition-colors cursor-pointer shadow-lg hover:shadow-xl"
    >
      Join Our Mission
    </button>
  </section>

  <!-- Tabbed Content Section -->
  <section class="px-4 py-8 md:py-12 bg-surface">
    <div class="max-w-4xl mx-auto">
      <!-- Tab Navigation -->
      <div class="flex justify-center overflow-x-auto pb-2 mb-6 scrollbar-hide">
        <div class="flex space-x-2">
          {#each tabs as tab, index}
            <button
              onclick={() => activeTab = index}
              class="flex-shrink-0 px-4 py-3 rounded-lg font-medium text-sm transition-all duration-200 whitespace-nowrap
                     {activeTab === index
                       ? 'bg-primary text-white shadow-md'
                       : 'bg-background text-text-secondary hover:bg-background/80 border border-outline'}"
            >
              {tab.title}
            </button>
          {/each}
        </div>
      </div>

      <!-- Tab Content -->
      <div class="transition-all duration-300">
        {#each tabs as tab, index}
          {#if activeTab === index}
            <div class="animate-fade-in">
              <div class="text-center mb-6">
                <h2 class="text-2xl md:text-3xl font-semibold text-text-primary mb-3">
                  {tab.content.heading}
                </h2>
                {#if tab.content.subheading}
                  <p class="text-base text-text-secondary leading-relaxed max-w-2xl mx-auto">
                    {tab.content.subheading}
                  </p>
                {/if}
              </div>

              <div class="space-y-4">
                {#if Array.isArray(tab.content.items) && typeof tab.content.items[0] === 'string'}
                  <!-- Simple list items (Challenge & Solution tabs) -->
                  {#each tab.content.items as item, itemIndex}
                    <div class="bg-background p-4 rounded-lg shadow-sm border border-outline">
                      <div class="flex items-start gap-3">
                        <div class="w-2 h-2 {index === 0 ? 'bg-primary' : 'bg-tertiary'} rounded-full mt-2 flex-shrink-0"></div>
                        <p class="text-text-secondary text-sm leading-relaxed">
                          {#if index === 1}
                            <strong>{item.split(' ')[0]}</strong> {item.substring(item.indexOf(' ') + 1)}
                          {:else}
                            {item}
                          {/if}
                        </p>
                      </div>
                    </div>
                  {/each}
                {:else}
                  <!-- Card items (Audience & Differentiation tabs) -->
                  <div class="grid gap-4 {index === 2 ? 'md:grid-cols-2' : 'md:grid-cols-3'}">
                    {#each tab.content.items as item}
                      <div class="bg-background p-5 rounded-lg shadow-sm border border-outline text-left">
                        <h3 class="text-lg font-semibold text-text-primary mb-3">
                          {item.title}
                        </h3>
                        <p class="text-text-secondary text-sm leading-relaxed">
                          {item.description}
                        </p>
                      </div>
                    {/each}
                  </div>
                {/if}
              </div>

              {#if tab.content.footer}
                <div class="mt-6 text-center">
                  <p class="text-base text-text-primary font-medium">
                    {tab.content.footer}
                  </p>
                </div>
              {/if}
            </div>
          {/if}
        {/each}
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
        <form onsubmit={handleSubmit} class="space-y-6">
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
        Built by nurses, for people. Your health journey, simplified.
      </p>
    </div>
  </footer>
</main>

<!-- Survey Modal -->
<SurveyModal 
  bind:isOpen={showSurveyModal} 
  userEmail={email} 
/>
