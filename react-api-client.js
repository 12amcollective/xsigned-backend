// API configuration for React frontend
// Save this as src/config/api.js in your React project

const API_CONFIG = {
  // Use environment variable or fallback to Pi IP
  baseURL: process.env.REACT_APP_API_URL || 'http://192.168.86.70/api',
  
  // For local development
  localURL: process.env.REACT_APP_API_URL_LOCAL || 'http://localhost:5001/api',
  
  // Headers
  headers: {
    'Content-Type': 'application/json',
  },
  
  // Timeout
  timeout: 10000,
};

// Helper function to get the correct API URL
export const getApiUrl = () => {
  // Check if we're in development mode
  const isDevelopment = process.env.NODE_ENV === 'development';
  const isLocalhost = window.location.hostname === 'localhost' || 
                     window.location.hostname === '127.0.0.1';
  
  if (isDevelopment || isLocalhost) {
    return API_CONFIG.localURL;
  }
  
  return API_CONFIG.baseURL;
};

// API client class
class ApiClient {
  constructor() {
    this.baseURL = getApiUrl();
  }

  async request(endpoint, options = {}) {
    const url = `${this.baseURL}${endpoint}`;
    
    const config = {
      ...API_CONFIG,
      ...options,
      headers: {
        ...API_CONFIG.headers,
        ...options.headers,
      },
    };

    try {
      const response = await fetch(url, config);
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      return data;
    } catch (error) {
      console.error('API request failed:', error);
      throw error;
    }
  }

  // User endpoints
  async createUser(userData) {
    return this.request('/users/', {
      method: 'POST',
      body: JSON.stringify(userData),
    });
  }

  async getUser(userId) {
    return this.request(`/users/${userId}`);
  }

  // Campaign endpoints
  async createCampaign(campaignData) {
    return this.request('/campaigns/', {
      method: 'POST',
      body: JSON.stringify(campaignData),
    });
  }

  async getCampaign(campaignId) {
    return this.request(`/campaigns/${campaignId}`);
  }

  async updateCampaignProgress(campaignId, progressData) {
    return this.request(`/campaigns/${campaignId}/progress`, {
      method: 'PATCH',
      body: JSON.stringify(progressData),
    });
  }

  // Health check
  async healthCheck() {
    return this.request('/health');
  }
}

export default new ApiClient();
