// Analytics utilities for Firebase
import { getAnalytics, logEvent, setUserProperties } from 'firebase/analytics';
import { getFirebaseApp } from './firebase.js';

let analytics;
let initialized = false;

export function initAnalytics() {
  if (initialized || typeof window === 'undefined') {
    return;
  }

  try {
    analytics = getAnalytics(getFirebaseApp());
    initialized = true;
    
    // Set default user properties
    setUserProperties({
      platform: 'web',
      app_version: '2.0.0'
    });
    
    console.log('Analytics initialized successfully');
  } catch (error) {
    console.warn('Analytics initialization failed:', error);
  }
}

export function trackEmailValidationStart(email) {
  if (!analytics) return;
  
  try {
    logEvent(analytics, 'email_validation_start', {
      email_domain: email.split('@')[1]?.toLowerCase() || 'unknown',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.warn('Failed to track email validation start:', error);
  }
}

export function trackEmailValidationSuccess(email, validationTime) {
  if (!analytics) return;
  
  try {
    logEvent(analytics, 'email_validation_success', {
      email_domain: email.split('@')[1]?.toLowerCase() || 'unknown',
      validation_time_ms: validationTime,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.warn('Failed to track email validation success:', error);
  }
}

export function trackEmailValidationFailure(email, reason) {
  if (!analytics) return;
  
  try {
    logEvent(analytics, 'email_validation_failure', {
      email_domain: email.split('@')[1]?.toLowerCase() || 'unknown',
      failure_reason: reason,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.warn('Failed to track email validation failure:', error);
  }
}

export function trackSurveyStepViewed(step, userEmail) {
  if (!analytics) return;
  
  try {
    logEvent(analytics, 'survey_step_viewed', {
      step_number: step,
      user_email: userEmail,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.warn('Failed to track survey step:', error);
  }
}

export function trackSurveyStarted(userEmail) {
  if (!analytics) return;
  
  try {
    logEvent(analytics, 'survey_started', {
      user_email: userEmail,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.warn('Failed to track survey start:', error);
  }
}

export function trackSurveyCompleted(userEmail, completionTime) {
  if (!analytics) return;
  
  try {
    logEvent(analytics, 'survey_completed', {
      user_email: userEmail,
      completion_time_ms: completionTime,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.warn('Failed to track survey completion:', error);
  }
}

export function trackSurveyAbandoned(userEmail, lastStep) {
  if (!analytics) return;
  
  try {
    logEvent(analytics, 'survey_abandoned', {
      user_email: userEmail,
      last_step: lastStep,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.warn('Failed to track survey abandonment:', error);
  }
}

export function trackPageView(pageName) {
  if (!analytics) return;
  
  try {
    logEvent(analytics, 'page_view', {
      page_name: pageName,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.warn('Failed to track page view:', error);
  }
}

export function trackFormSubmission(email, source) {
  if (!analytics) return;
  
  try {
    logEvent(analytics, 'form_submission', {
      form_type: 'email_signup',
      source: source,
      email_domain: email.split('@')[1]?.toLowerCase() || 'unknown',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.warn('Failed to track form submission:', error);
  }
}

export function trackError(error, context) {
  if (!analytics) return;
  
  try {
    logEvent(analytics, 'error', {
      error_message: error.message || 'Unknown error',
      error_context: context,
      timestamp: new Date().toISOString(),
      user_agent: navigator.userAgent
    });
  } catch (err) {
    console.warn('Failed to track error:', err);
  }
}