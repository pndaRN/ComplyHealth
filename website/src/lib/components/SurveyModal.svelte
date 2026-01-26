<script>
  import {
    getDb,
    collection,
    query,
    where,
    getDocs,
    updateDoc,
    serverTimestamp,
  } from "$lib/firebase.js";

  let { isOpen = false, userEmail = "" } = $props();

  let currentStep = $state(1);
  let surveyData = $state({
    age_range: "",
    conditions_count: "",
    medications_count: "",
    health_difficulties: [],
    tracking_methods: [],
    single_place_usefulness: "",
    priority_preference: "",
    condition_understanding: 0,
    biggest_challenge: "",
    biggest_challenge_other: "",
    open_to_conversation: false,
    conversation_email: "",
    interested_in_beta: false,
    beta_email: "",
  });

  let isSubmitting = $state(false);

  const totalSteps = 11;

  function toggleCheckbox(field, value, isChecked) {
    if (isChecked) {
      surveyData[field] = [...surveyData[field], value];
    } else {
      surveyData[field] = surveyData[field].filter((v) => v !== value);
    }
  }

  function canProceedToNext() {
    switch (currentStep) {
      case 1:
        return surveyData.age_range !== "";
      case 2:
        return surveyData.conditions_count !== "";
      case 3:
        return surveyData.medications_count !== "";
      case 4:
        return surveyData.health_difficulties.length > 0;
      case 5:
        return surveyData.tracking_methods.length > 0;
      case 6:
        return surveyData.single_place_usefulness !== "";
      case 7:
        return surveyData.priority_preference !== "";
      case 8:
        return surveyData.condition_understanding > 0;
      case 9:
        return (
          surveyData.biggest_challenge !== "" &&
          (surveyData.biggest_challenge !== "Other" ||
            surveyData.biggest_challenge_other.trim() !== "")
        );
      case 10:
        return true;
      case 11:
        return true;
      default:
        return false;
    }
  }

  function closeModal() {
    isOpen = false;
    currentStep = 1;
  }

  function nextStep() {
    if (currentStep < totalSteps) {
      currentStep++;
    }
  }

  function prevStep() {
    if (currentStep > 1) {
      currentStep--;
    }
  }

  async function submitSurvey() {
    isSubmitting = true;

    try {
      console.log("Submitting survey for email:", userEmail);
      const db = getDb();
      const supportersRef = collection(db, "mission_supporters");
      const q = query(supportersRef, where("email", "==", userEmail));
      const querySnapshot = await getDocs(q);

      console.log("Found documents:", querySnapshot.size);

      if (!querySnapshot.empty) {
        const docRef = querySnapshot.docs[0].ref;
        await updateDoc(docRef, {
          survey_responses: surveyData,
          status: "surveyed",
          survey_completed: serverTimestamp(),
        });

        console.log("Survey updated successfully");
        currentStep = "complete";
      } else {
        console.error(
          "No mission supporter document found for email:",
          userEmail,
        );
      }
    } catch (error) {
      console.error("Survey submission error:", error);
    } finally {
      isSubmitting = false;
    }
  }

  function getProgressPercentage() {
    return (currentStep / totalSteps) * 100;
  }
</script>

<!-- Survey Modal -->
{#if isOpen}
  <div
    class="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50"
  >
    <div
      class="bg-background rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto shadow-2xl"
    >
      <!-- Header -->
      <div class="sticky top-0 bg-background border-b border-outline p-6">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-xl font-semibold text-text-primary">
            Help Us Build What You Need
          </h3>
          <button
            onclick={closeModal}
            class="text-text-secondary hover:text-text-primary transition-colors"
            aria-label="Close survey modal"
          >
            <svg
              class="w-6 h-6"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              ></path>
            </svg>
          </button>
        </div>

        <!-- Progress Bar -->
        {#if currentStep !== "complete"}
          <div class="w-full bg-surface rounded-full h-2">
            <div
              class="bg-primary h-2 rounded-full transition-all duration-300"
              style="width: {getProgressPercentage()}%"
            ></div>
          </div>
          <p class="text-sm text-text-secondary mt-2">
            Step {currentStep} of {totalSteps}
          </p>
        {/if}
      </div>

      <!-- Content -->
      <div class="p-6">
        <!-- Step 1: Age Range -->
        {#if currentStep === 1}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-4">
              What is your age range?
            </h4>
            <div class="space-y-3">
              {#each ["18-30", "30-40", "40-50", "50-60", "60+"] as option}
                <label
                  class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors"
                >
                  <input
                    type="radio"
                    bind:group={surveyData.age_range}
                    value={option}
                    class="w-4 h-4 text-primary"
                  />
                  <span class="text-text-primary text-lg">{option}</span>
                </label>
              {/each}
            </div>
          </div>

          <!-- Step 2: Chronic Conditions Count -->
        {:else if currentStep === 2}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-4">
              How many chronic conditions do you live with?
            </h4>
            <div class="space-y-3">
              {#each ["0", "1-2", "3-5", "5+"] as option}
                <label
                  class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors"
                >
                  <input
                    type="radio"
                    bind:group={surveyData.conditions_count}
                    value={option}
                    class="w-4 h-4 text-primary"
                  />
                  <span class="text-text-primary text-lg">{option}</span>
                </label>
              {/each}
            </div>
          </div>

          <!-- Step 3: Medications Count -->
        {:else if currentStep === 3}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-4">
              How many medications do you take daily?
            </h4>
            <div class="space-y-3">
              {#each ["0-1", "2-4", "4-6", "7+"] as option}
                <label
                  class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors"
                >
                  <input
                    type="radio"
                    bind:group={surveyData.medications_count}
                    value={option}
                    class="w-4 h-4 text-primary"
                  />
                  <span class="text-text-primary text-lg">{option}</span>
                </label>
              {/each}
            </div>
          </div>

          <!-- Step 4: Health Difficulties (Checkbox) -->
        {:else if currentStep === 4}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-2">
              What do you find MOST difficult about managing your health day to
              day?
            </h4>
            <p class="text-sm text-text-secondary mb-4">
              Select all that apply
            </p>
            <div class="space-y-3">
              {#each ["Remembering to take medications", "Keeping track of multiple doctors appointments", "Feeling overwhelmed or burnt out", "Remembering instructions from doctors appointments", "Organizing all health information", "Understanding what condition means", "Understanding why certain medications are taken", "Tracking symptoms"] as option}
                <label
                  class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors"
                >
                  <input
                    type="checkbox"
                    checked={surveyData.health_difficulties.includes(option)}
                    onchange={(e) =>
                      toggleCheckbox(
                        "health_difficulties",
                        option,
                        e.target.checked,
                      )}
                    class="w-4 h-4 text-primary rounded"
                  />
                  <span class="text-text-primary">{option}</span>
                </label>
              {/each}
            </div>
          </div>

          <!-- Step 5: Tracking Methods (Checkbox) -->
        {:else if currentStep === 5}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-2">
              How do you currently keep track of all your health information?
            </h4>
            <p class="text-sm text-text-secondary mb-4">
              Select all that apply
            </p>
            <div class="space-y-3">
              {#each ["Memory only", "Paper notes", "Loved ones keep track", "Mobile apps", "Patient portals", "No system"] as option}
                <label
                  class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors"
                >
                  <input
                    type="checkbox"
                    checked={surveyData.tracking_methods.includes(option)}
                    onchange={(e) =>
                      toggleCheckbox(
                        "tracking_methods",
                        option,
                        e.target.checked,
                      )}
                    class="w-4 h-4 text-primary rounded"
                  />
                  <span class="text-text-primary">{option}</span>
                </label>
              {/each}
            </div>
          </div>

          <!-- Step 6: Single Place Usefulness -->
        {:else if currentStep === 6}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-4">
              If there were one simple place to track meds, conditions,
              appointments, and personal notes, how useful would that be?
            </h4>
            <div class="space-y-3">
              {#each ["Extremely helpful", "Helpful", "Somewhat helpful", "Not helpful"] as option}
                <label
                  class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors"
                >
                  <input
                    type="radio"
                    bind:group={surveyData.single_place_usefulness}
                    value={option}
                    class="w-4 h-4 text-primary"
                  />
                  <span class="text-text-primary text-lg">{option}</span>
                </label>
              {/each}
            </div>
          </div>

          <!-- Step 7: Priority Preference -->
        {:else if currentStep === 7}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-4">
              Which is more important?
            </h4>
            <div class="space-y-3">
              {#each ["Organized system", "Education on conditions/medications"] as option}
                <label
                  class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors"
                >
                  <input
                    type="radio"
                    bind:group={surveyData.priority_preference}
                    value={option}
                    class="w-4 h-4 text-primary"
                  />
                  <span class="text-text-primary text-lg">{option}</span>
                </label>
              {/each}
            </div>
          </div>

          <!-- Step 8: Condition Understanding Scale -->
        {:else if currentStep === 8}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-4">
              On a scale of 1-10, how well do you understand your chronic health
              conditions?
            </h4>
            <p class="text-sm text-text-secondary mb-4">
              1 = Not at all, 10 = Completely
            </p>
            <div class="flex flex-wrap gap-2 justify-center">
              {#each [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as num}
                <button
                  type="button"
                  onclick={() => (surveyData.condition_understanding = num)}
                  class="w-12 h-12 rounded-lg border-2 font-medium text-lg transition-all {surveyData.condition_understanding ===
                  num
                    ? 'bg-primary border-primary text-white'
                    : 'border-outline text-text-primary hover:border-primary/50'}"
                >
                  {num}
                </button>
              {/each}
            </div>
          </div>

          <!-- Step 9: Biggest Challenge (Radio with Other) -->
        {:else if currentStep === 9}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-4">
              What is the single biggest challenge you face when managing your
              health?
            </h4>
            <div class="space-y-3">
              {#each ["Keeping track of medications", "Feeling overwhelmed", "Managing information across platforms", "Remembering appointments", "Understanding condition", "Emotional stress/anxiety", "Understanding health plan", "Other"] as option}
                <label
                  class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors"
                >
                  <input
                    type="radio"
                    bind:group={surveyData.biggest_challenge}
                    value={option}
                    class="w-4 h-4 text-primary"
                  />
                  <span class="text-text-primary">{option}</span>
                </label>
              {/each}
              {#if surveyData.biggest_challenge === "Other"}
                <input
                  type="text"
                  bind:value={surveyData.biggest_challenge_other}
                  placeholder="Please specify..."
                  class="w-full px-4 py-3 border border-outline rounded-lg focus:border-primary focus:ring-2 focus:ring-primary/20 transition-colors mt-2"
                />
              {/if}
            </div>
          </div>

          <!-- Step 10: Open to Conversation -->
        {:else if currentStep === 10}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-4">
              Would you be open to a quick 3-5 minute conversation?
            </h4>
            <p class="text-sm text-text-secondary mb-4">
              This is optional but helps us understand your needs better.
            </p>
            <div class="space-y-3">
              <label
                class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors"
              >
                <input
                  type="radio"
                  name="open_to_conversation"
                  checked={surveyData.open_to_conversation === true}
                  onchange={() => (surveyData.open_to_conversation = true)}
                  class="w-4 h-4 text-primary"
                />
                <span class="text-text-primary text-lg">Yes</span>
              </label>
              <label
                class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors"
              >
                <input
                  type="radio"
                  name="open_to_conversation"
                  checked={surveyData.open_to_conversation === false}
                  onchange={() => {
                    surveyData.open_to_conversation = false;
                    surveyData.conversation_email = "";
                  }}
                  class="w-4 h-4 text-primary"
                />
                <span class="text-text-primary text-lg">No</span>
              </label>
              {#if surveyData.open_to_conversation}
                <div class="mt-4">
                  <label class="block text-sm text-text-secondary mb-2">
                    Best email to reach you:
                    <input
                      type="email"
                      bind:value={surveyData.conversation_email}
                      placeholder="your@email.com"
                      class="w-full px-4 py-3 border border-outline rounded-lg focus:border-primary focus:ring-2 focus:ring-primary/20 transition-colors mt-1"
                    />
                  </label>
                </div>
              {/if}
            </div>
          </div>

          <!-- Step 11: Beta Tester Interest -->
        {:else if currentStep === 11}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-4">
              Would you like to be an early beta tester for a mobile app?
            </h4>
            <p class="text-sm text-text-secondary mb-4">
              This is optional. Beta testers get early access to new features.
            </p>
            <div class="space-y-3">
              <label
                class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors"
              >
                <input
                  type="radio"
                  name="interested_in_beta"
                  checked={surveyData.interested_in_beta === true}
                  onchange={() => (surveyData.interested_in_beta = true)}
                  class="w-4 h-4 text-primary"
                />
                <span class="text-text-primary text-lg">Yes</span>
              </label>
              <label
                class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors"
              >
                <input
                  type="radio"
                  name="interested_in_beta"
                  checked={surveyData.interested_in_beta === false}
                  onchange={() => {
                    surveyData.interested_in_beta = false;
                    surveyData.beta_email = "";
                  }}
                  class="w-4 h-4 text-primary"
                />
                <span class="text-text-primary text-lg">No</span>
              </label>
              {#if surveyData.interested_in_beta}
                <div class="mt-4">
                  <label class="block text-sm text-text-secondary mb-2">
                    Best email to reach you:
                    <input
                      type="email"
                      bind:value={surveyData.beta_email}
                      placeholder="your@email.com"
                      class="w-full px-4 py-3 border border-outline rounded-lg focus:border-primary focus:ring-2 focus:ring-primary/20 transition-colors mt-1"
                    />
                  </label>
                </div>
              {/if}
            </div>
          </div>

          <!-- Complete -->
        {:else if currentStep === "complete"}
          <div class="text-center py-8">
            <div
              class="w-16 h-16 bg-tertiary/10 rounded-full flex items-center justify-center mx-auto mb-4"
            >
              <svg
                class="w-8 h-8 text-tertiary"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                ></path>
              </svg>
            </div>
            <h4 class="text-xl font-semibold text-text-primary mb-2">
              Thank you!
            </h4>
            <p class="text-text-secondary mb-6">
              Your input helps us build what you actually need. We'll keep you
              updated on our progress.
            </p>
            <button
              onclick={closeModal}
              class="bg-primary hover:bg-primary/90 text-white font-medium px-6 py-3 rounded-lg transition-colors"
            >
              Got it!
            </button>
          </div>
        {/if}
      </div>

      <!-- Footer -->
      {#if currentStep !== "complete"}
        <div class="sticky bottom-0 bg-background border-t border-outline p-6">
          <div class="flex justify-between items-center">
            <button
              onclick={prevStep}
              disabled={currentStep === 1}
              class="px-4 py-2 text-text-secondary hover:text-text-primary disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              Previous
            </button>

            {#if currentStep < totalSteps}
              <button
                onclick={nextStep}
                disabled={!canProceedToNext()}
                class="bg-primary hover:bg-primary/90 disabled:bg-primary/50 disabled:cursor-not-allowed text-white font-medium px-6 py-2 rounded-lg transition-colors"
              >
                Next
              </button>
            {:else}
              <button
                onclick={submitSurvey}
                disabled={isSubmitting}
                class="bg-primary hover:bg-primary/90 disabled:bg-primary/50 disabled:cursor-not-allowed text-white font-medium px-6 py-2 rounded-lg transition-colors"
              >
                {#if isSubmitting}
                  <span class="flex items-center gap-2">
                    <svg
                      class="animate-spin w-4 h-4"
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
                    Submitting...
                  </span>
                {:else}
                  Submit Survey
                {/if}
              </button>
            {/if}
          </div>
        </div>
      {/if}
    </div>
  </div>
{/if}
