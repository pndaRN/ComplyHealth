// Browser-compatible email validation (simplified for client-side)
import { getDb, collection, query, where, getDocs } from './firebase.js';

// List of common disposable email domains (can be expanded)
const disposableDomains = [
  '10minutemail.com', 'tempmail.org', 'guerrillamail.com',
  'mailinator.com', 'yopmail.com', 'temp-mail.org',
  'throwaway.email', 'sharklasers.com', 'maildrop.cc'
];

const VALIDATION_TIMEOUT = 30000; // 30 seconds

export async function validateEmail(email) {
  const startTime = Date.now();
  
  try {
    // 1. Basic format check
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return { valid: false, reason: 'invalid_format', retry: true };
    }
    
    // 2. Domain extraction and validation
    const domain = email.split('@')[1].toLowerCase();
    if (!domain || domain.length < 3) {
      return { valid: false, reason: 'domain_invalid', retry: true };
    }
    
    // 3. Disposable email detection
    if (isDisposableEmail(domain)) {
      return { valid: false, reason: 'disposable_email', retry: false };
    }
    
    // 4. Basic domain validation (check if domain has common structure)
    if (!hasValidDomainStructure(domain)) {
      return { valid: false, reason: 'domain_invalid', retry: true };
    }
    
    // 5. Duplicate check
    const duplicateCheck = await checkDuplicateEmail(email);
    if (duplicateCheck.isDuplicate) {
      return { valid: false, reason: 'duplicate_email', retry: false };
    }
    
    return { 
      valid: true, 
      details: {
        valid: true,
        disposable: false,
        domain: domain
      },
      validationTime: Date.now() - startTime
    };
    
  } catch (error) {
    console.error('Email validation error:', error);
    return { valid: false, reason: 'validation_error', retry: true };
  }
}

function isDisposableEmail(domain) {
  // Check exact matches
  if (disposableDomains.includes(domain)) {
    return true;
  }
  
  // Check for patterns common in disposable emails
  const disposablePatterns = [
    /temp.*mail/, /throwaway/, /10minute/, /guerrilla/,
    /yopmail/, /mailinator/, /tempmail/
  ];
  
  return disposablePatterns.some(pattern => pattern.test(domain));
}

function hasValidDomainStructure(domain) {
  // Basic domain structure validation
  const domainRegex = /^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?(\.[a-zA-Z]{2,})+$/;
  return domainRegex.test(domain);
}

async function checkDuplicateEmail(email) {
  try {
    const db = getDb();
    const supportersRef = collection(db, "mission_supporters");
    const q = query(supportersRef, where("email", "==", email));
    const querySnapshot = await getDocs(q);
    
    if (!querySnapshot.empty) {
      return { isDuplicate: true };
    }
    
    return { isDuplicate: false };
  } catch (error) {
    console.error('Duplicate check error:', error);
    // Allow submission if duplicate check fails
    return { isDuplicate: false };
  }
}

export const errorMessages = {
  'invalid_format': 'Please enter a valid email address',
  'disposable_email': 'Please use your permanent email address',
  'domain_invalid': 'This email domain appears to be invalid',
  'mx_record_fail': 'This email domain cannot receive emails',
  'validation_error': 'Unable to verify email. Please try again.',
  'timeout': 'Email verification took too long. Please try again.',
  'duplicate_email': 'This email has already joined our mission!'
};