<script>
  import { getDb, collection, query, where, getDocs, updateDoc, serverTimestamp } from '$lib/firebase.js';
  
  let { isOpen = false, userEmail = "" } = $props();
  
  let currentStep = $state(1);
  let surveyData = $state({
    conditions_count: "",
    medications_count: "",
    hardest_part: "",
    tools_tried: "",
    stress_reduction_vision: ""
  });
  
  let isSubmitting = $state(false);
  
  const totalSteps = 5;
  
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
          survey_completed: serverTimestamp()
        });

        console.log("Survey updated successfully");
        currentStep = "complete";
      } else {
        console.error("No mission supporter document found for email:", userEmail);
      }
    } catch (error) {
      console.error('Survey submission error:', error);
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
  <div class="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
    <div class="bg-background rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto shadow-2xl">
      
      <!-- Header -->
      <div class="sticky top-0 bg-background border-b border-outline p-6">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-xl font-semibold text-text-primary">Help Us Build What You Need</h3>
          <button 
            onclick={closeModal}
            class="text-text-secondary hover:text-text-primary transition-colors"
            aria-label="Close survey modal"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
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
          <p class="text-sm text-text-secondary mt-2">Step {currentStep} of {totalSteps}</p>
        {/if}
      </div>
      
      <!-- Content -->
      <div class="p-6">
        {#if currentStep === 1}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-4">How many chronic conditions are you managing?</h4>
            <div class="space-y-3">
              <label class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors">
                <input type="radio" bind:group={surveyData.conditions_count} value="0-1" class="w-4 h-4 text-primary" />
                <span class="text-text-primary text-lg">0-1</span>
              </label>
              <label class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors">
                <input type="radio" bind:group={surveyData.conditions_count} value="2-3" class="w-4 h-4 text-primary" />
                <span class="text-text-primary text-lg">2-3</span>
              </label>
              <label class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors">
                <input type="radio" bind:group={surveyData.conditions_count} value="4-5" class="w-4 h-4 text-primary" />
                <span class="text-text-primary text-lg">4-5</span>
              </label>
              <label class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors">
                <input type="radio" bind:group={surveyData.conditions_count} value="6+" class="w-4 h-4 text-primary" />
                <span class="text-text-primary text-lg">6+</span>
              </label>
            </div>
          </div>
        {:else if currentStep === 2}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-4">How many medications do you take daily?</h4>
            <div class="space-y-3">
              <label class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors">
                <input type="radio" bind:group={surveyData.medications_count} value="0-2" class="w-4 h-4 text-primary" />
                <span class="text-text-primary text-lg">0-2</span>
              </label>
              <label class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors">
                <input type="radio" bind:group={surveyData.medications_count} value="3-5" class="w-4 h-4 text-primary" />
                <span class="text-text-primary text-lg">3-5</span>
              </label>
              <label class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors">
                <input type="radio" bind:group={surveyData.medications_count} value="6-10" class="w-4 h-4 text-primary" />
                <span class="text-text-primary text-lg">6-10</span>
              </label>
              <label class="flex items-center gap-3 p-3 border border-outline rounded-lg hover:border-primary/50 cursor-pointer transition-colors">
                <input type="radio" bind:group={surveyData.medications_count} value="11+" class="w-4 h-4 text-primary" />
                <span class="text-text-primary text-lg">11+</span>
              </label>
            </div>
          </div>
        {:else if currentStep === 3}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-4">What's the hardest part about managing your health day-to-day?</h4>
            <textarea
              bind:value={surveyData.hardest_part}
              rows="4"
              class="w-full px-4 py-3 border border-outline rounded-lg focus:border-primary focus:ring-2 focus:ring-primary/20 transition-colors resize-none"
              placeholder="Tell us about your biggest challenges..."
            ></textarea>
          </div>
        {:else if currentStep === 4}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-4">What tools have you tried to help with this?</h4>
            <textarea
              bind:value={surveyData.tools_tried}
              rows="4"
              class="w-full px-4 py-3 border border-outline rounded-lg focus:border-primary focus:ring-2 focus:ring-primary/20 transition-colors resize-none"
              placeholder="Apps, notebooks, spreadsheets, anything you've tried..."
            ></textarea>
          </div>
        {:else if currentStep === 5}
          <div class="survey-step">
            <h4 class="text-lg font-medium text-text-primary mb-4">If something could reduce your health management stress by 20%, what would that look like for you?</h4>
            <textarea
              bind:value={surveyData.stress_reduction_vision}
              rows="4"
              class="w-full px-4 py-3 border border-outline rounded-lg focus:border-primary focus:ring-2 focus:ring-primary/20 transition-colors resize-none"
              placeholder="Describe what would make the biggest difference..."
            ></textarea>
          </div>
        {:else if currentStep === "complete"}
          <div class="text-center py-8">
            <div class="w-16 h-16 bg-tertiary/10 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg class="w-8 h-8 text-tertiary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
              </svg>
            </div>
            <h4 class="text-xl font-semibold text-text-primary mb-2">Thank you!</h4>
            <p class="text-text-secondary mb-6">Your input helps us build what you actually need. We'll keep you updated on our progress.</p>
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
                disabled={
                  (currentStep === 1 && !surveyData.conditions_count) ||
                  (currentStep === 2 && !surveyData.medications_count)
                }
                class="bg-primary hover:bg-primary/90 disabled:bg-primary/50 disabled:cursor-not-allowed text-white font-medium px-6 py-2 rounded-lg transition-colors"
              >
                Next
              </button>
            {:else}
              <button
                onclick={submitSurvey}
                disabled={isSubmitting || !surveyData.hardest_part || !surveyData.tools_tried || !surveyData.stress_reduction_vision}
                class="bg-primary hover:bg-primary/90 disabled:bg-primary/50 disabled:cursor-not-allowed text-white font-medium px-6 py-2 rounded-lg transition-colors"
              >
                {#if isSubmitting}
                  <span class="flex items-center gap-2">
                    <svg class="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
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