// Performance optimization utilities

// Simple in-memory cache for validation results
const validationCache = new Map();
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

export function cacheValidationResult(email, result) {
  validationCache.set(email.toLowerCase(), {
    result,
    timestamp: Date.now()
  });
}

export function getCachedValidationResult(email) {
  const cached = validationCache.get(email.toLowerCase());
  
  if (!cached) {
    return null;
  }
  
  // Check if cache is still valid
  if (Date.now() - cached.timestamp > CACHE_DURATION) {
    validationCache.delete(email.toLowerCase());
    return null;
  }
  
  return cached.result;
}

// Throttle function for rapid validation attempts
export function throttle(fn, delay) {
  let lastCall = 0;
  let timeoutId;
  
  return function(...args) {
    const now = Date.now();
    
    if (now - lastCall < delay) {
      clearTimeout(timeoutId);
      timeoutId = setTimeout(() => {
        lastCall = now;
        fn.apply(this, args);
      }, delay - (now - lastCall));
    } else {
      lastCall = now;
      fn.apply(this, args);
    }
  };
}

// Debounce function for validation inputs
export function debounce(fn, delay) {
  let timeoutId;
  
  return function(...args) {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn.apply(this, args), delay);
  };
}