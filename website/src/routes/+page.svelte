<script>
  import { getDb } from "$lib/firebase.js";
  import { collection, addDoc, serverTimestamp } from "firebase/firestore";

  let name = $state("");
  let email = $state("");
  let platform = $state("");
  let challenges = $state("");
  let isSubmitting = $state(false);
  let submitStatus = $state(""); // 'success' | 'error' | ''
  let errorMessage = $state("");

  async function handleSubmit(event) {
    event.preventDefault();

    if (!name || !email || !platform) {
      errorMessage = "Please fill in all required fields.";
      submitStatus = "error";
      return;
    }

    isSubmitting = true;
    submitStatus = "";
    errorMessage = "";

    try {
      const db = getDb();
      await addDoc(collection(db, "beta_signups"), {
        name,
        email,
        platform,
        challenges: challenges || "",
        timestamp: serverTimestamp(),
        status: "pending",
      });

      submitStatus = "success";
      name = "";
      email = "";
      platform = "";
      challenges = "";
    } catch (error) {
      console.error("Error submitting form:", error);
      submitStatus = "error";
      errorMessage = "Something went wrong. Please try again.";
    } finally {
      isSubmitting = false;
    }
  }

  function scrollToSignup() {
    document.getElementById("signup")?.scrollIntoView({ behavior: "smooth" });
  }
</script>

<main class="min-h-screen">
  <!-- Header -->
  <header class="px-6 py-4">
    <img src="/complyhealth-logo.svg" alt="ComplyHealth" class="h-10" />
  </header>

  <!-- Hero Section -->
  <section class="px-6 py-20 md:py-32 max-w-4xl mx-auto text-center">
    <h1
      class="text-4xl md:text-5xl lg:text-6xl font-semibold text-text-primary mb-6"
    >
      Take control of your health with confidence
    </h1>
    <p
      class="text-lg md:text-xl text-text-secondary max-w-2xl mx-auto mb-10 leading-relaxed"
    >
      ComplyHealth is built by nurses to help adults stay organized, informed, and confident while managing their chronic health conditions. 
      ComplyHealth provides the support you can trust as you take control of your health. 
    </p>
    <button
      onclick={scrollToSignup}
      class="bg-primary hover:bg-primary/90 text-white font-medium px-8 py-4 rounded-lg text-lg transition-colors cursor-pointer shadow-lg hover:shadow-xl"
    >
      Join the Beta
    </button>
  </section>

  <!-- Features Section -->
  <section class="px-6 py-16 md:py-24 bg-surface">
    <div class="max-w-6xl mx-auto">
      <div class="grid md:grid-cols-3 gap-8">
        <!-- Feature 1 -->
        <div
          class="bg-background p-8 rounded-xl shadow-sm border border-outline"
        >
          <div
            class="w-14 h-14 bg-primary/10 rounded-xl flex items-center justify-center mb-6"
          >
            <svg
              class="w-7 h-7 text-primary"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
              />
            </svg>
          </div>
          <h3 class="text-xl font-semibold text-text-primary mb-3">
            Who it's for?
          </h3>
          <p class="text-text-secondary">
            This app is for people who:<br>
            • Live with one or more chronic health conditions<br>
            • Take multiple medications<br>
            • Feel overwhelmed keeping track of health information<br>
            • Want clearer understanding and better organization
          </p>
        </div>

        <!-- Feature 2 -->
        <div
          class="bg-background p-8 rounded-xl shadow-sm border border-outline"
        >
          <div
            class="w-14 h-14 bg-secondary/10 rounded-xl flex items-center justify-center mb-6"
          >
            <svg
              class="w-7 h-7 text-secondary"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
              />
            </svg>
          </div>
          <h3 class="text-xl font-semibold text-text-primary mb-3">
            What makes us different?
          </h3>
          <p class="text-text-secondary">
            • Built by Nurses. Designed for real life.<br>
            • Everything is designed to be simple and supportive.<br>
            • You are the focus.
          </p>
        </div>

        <!-- Feature 3 -->
        <div
          class="bg-background p-8 rounded-xl shadow-sm border border-outline"
        >
          <div
            class="w-14 h-14 bg-tertiary/10 rounded-xl flex items-center justify-center mb-6"
          >
            <svg
              class="w-7 h-7 text-tertiary"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
              />
            </svg>
          </div>
          <h3 class="text-xl font-semibold text-text-primary mb-3">
            Privacy & Trust
          </h3>
          <p class="text-text-secondary">
            • Your Health. Your Data.<br>
            • Your information stays on your device. You stay in control.<br>
            • Encrypted for your safety.
          </p>
        </div>
      </div>
    </div>
  </section>

  <!-- Beta Signup Section -->
  <section id="signup" class="px-6 py-16 md:py-24">
    <div class="max-w-xl mx-auto">
      <h2
        class="text-3xl md:text-4xl font-semibold text-text-primary text-center mb-4"
      >
        Join the Beta
      </h2>
      <p class="text-text-secondary text-center mb-10">
        Join for early access and help shape the future of patient-centered health tools.
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
          <p class="font-medium text-lg">Thanks for signing up!</p>
          <p class="mt-2 text-tertiary/80">
            We'll be in touch soon with beta access.
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
              for="name"
              class="block text-sm font-medium text-text-primary mb-2"
            >
              Name <span class="text-error">*</span>
            </label>
            <input
              type="text"
              id="name"
              bind:value={name}
              required
              class="w-full px-4 py-3 rounded-lg border border-outline bg-background text-text-primary focus:border-primary focus:ring-2 focus:ring-primary/20 transition-colors"
              placeholder="Your name"
            />
          </div>

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

          <fieldset>
            <legend class="block text-sm font-medium text-text-primary mb-3">
              Platform preference <span class="text-error">*</span>
            </legend>
            <div class="flex flex-wrap gap-4">
              <label class="flex items-center gap-2 cursor-pointer">
                <input
                  type="radio"
                  name="platform"
                  value="iOS"
                  bind:group={platform}
                  required
                  class="w-4 h-4 text-primary focus:ring-primary"
                />
                <span class="text-text-primary">iOS</span>
              </label>
              <label class="flex items-center gap-2 cursor-pointer">
                <input
                  type="radio"
                  name="platform"
                  value="Android"
                  bind:group={platform}
                  class="w-4 h-4 text-primary focus:ring-primary"
                />
                <span class="text-text-primary">Android</span>
              </label>
              <label class="flex items-center gap-2 cursor-pointer">
                <input
                  type="radio"
                  name="platform"
                  value="Both"
                  bind:group={platform}
                  class="w-4 h-4 text-primary focus:ring-primary"
                />
                <span class="text-text-primary">Both</span>
              </label>
            </div>
          </fieldset>

          <div>
            <label
              for="challenges"
              class="block text-sm font-medium text-text-primary mb-2"
            >
              What are the biggest challenges you face daily when it comes to managing your chronic health needs?
              <span class="text-text-secondary font-normal">(optional)</span>
            </label>
            <textarea
              id="challenges"
              bind:value={challenges}
              rows="4"
              class="w-full px-4 py-3 rounded-lg border border-outline bg-background text-text-primary focus:border-primary focus:ring-2 focus:ring-primary/20 transition-colors resize-none"
              placeholder="What's been difficult about managing medications?"
            ></textarea>
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
                Signing up...
              </span>
            {:else}
              Sign Up for Beta
            {/if}
          </button>
        </form>
      {/if}
    </div>
  </section>

  <!-- Footer -->
  <footer class="px-6 py-8 border-t border-outline">
    <div class="max-w-6xl mx-auto text-center text-text-secondary text-sm">
      <p>&copy; 2025 ComplyHealth. All rights reserved.</p>
    </div>
  </footer>
</main>
