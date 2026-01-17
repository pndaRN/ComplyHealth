import { writable, derived } from 'svelte/store';
import { browser } from '$app/environment';

/**
 * Theme store for managing dark mode state
 * Automatically detects system preference and allows manual override
 */

// Create stores
export const theme = writable('light');
export const systemPreference = writable('light');
export const manualOverride = writable(false);

// Derived stores
export const isDark = derived(theme, $theme => {
  console.log('isDark derived:', $theme === 'dark', 'theme:', $theme);
  return $theme === 'dark';
});
export const isLight = derived(theme, $theme => $theme === 'light');

// Initialize theme detection
function initializeTheme() {
  if (!browser) return;

  // Check for saved preference
  const savedTheme = localStorage.getItem('theme');
  const savedOverride = localStorage.getItem('theme-override') === 'true';

  // Detect system preference
  const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
  const currentSystemPreference = mediaQuery.matches ? 'dark' : 'light';
  console.log('System preference detected:', currentSystemPreference, 'mediaQuery.matches:', mediaQuery.matches);
  systemPreference.set(currentSystemPreference);

  // Set initial theme
  if (savedOverride && savedTheme) {
    theme.set(savedTheme);
    manualOverride.set(true);
  } else {
    theme.set(currentSystemPreference);
    manualOverride.set(false);
  }

  // Listen for system preference changes
  mediaQuery.addEventListener('change', (e) => {
    const newSystemPreference = e.matches ? 'dark' : 'light';
    systemPreference.set(newSystemPreference);

    // Only auto-switch if no manual override
    manualOverride.subscribe($manualOverride => {
      if (!$manualOverride) {
        theme.set(newSystemPreference);
      }
    })();
  });
}

// Initialize on client side
if (browser) {
  console.log('Initializing theme store...');
  initializeTheme();
}

// Store actions
export const themeActions = {
  toggleTheme: () => {
    theme.update(current => {
      const newTheme = current === 'light' ? 'dark' : 'light';
      manualOverride.set(true);

      // Save preference
      localStorage.setItem('theme', newTheme);
      localStorage.setItem('theme-override', 'true');

      return newTheme;
    });
  },

  resetToSystem: () => {
    systemPreference.subscribe($systemPreference => {
      theme.set($systemPreference);
      manualOverride.set(false);

      // Clear saved preferences
      localStorage.removeItem('theme');
      localStorage.removeItem('theme-override');
    })();
  }
};