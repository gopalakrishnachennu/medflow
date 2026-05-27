import React, { useState, useEffect } from 'react';

// Mock data representing the 7 microservices
const initialMicroservices = [
  { id: 'auth-service', name: 'Auth Service', description: 'Handles JWT Authentication & User Management', icon: '🔒' },
  { id: 'patient-service', name: 'Patient Service', description: 'Patient Electronic Health Records & Profiles', icon: '🏥' },
  { id: 'appointment-service', name: 'Appointment Service', description: 'Scheduling and Calendar Management', icon: '📅' },
  { id: 'records-service', name: 'Records Service', description: 'Medical History and Diagnostics Storage', icon: '📂' },
  { id: 'pharmacy-service', name: 'Pharmacy Service', description: 'Prescription Management and Inventory', icon: '💊' },
  { id: 'billing-service', name: 'Billing Service', description: 'Invoicing, Insurance, and Payments', icon: '💳' },
  { id: 'notification-service', name: 'Notification Service', description: 'Email and SMS Patient Alerts', icon: '🔔' },
];

function App() {
  const [currentTime, setCurrentTime] = useState(new Date().toLocaleTimeString());
  const [statuses, setStatuses] = useState<Record<string, boolean>>({});

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date().toLocaleTimeString());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    const checkHealth = async () => {
      for (const service of initialMicroservices) {
        try {
          const res = await fetch(`/api/${service.id}/health`);
          setStatuses(prev => ({ ...prev, [service.id]: res.ok }));
        } catch (err) {
          setStatuses(prev => ({ ...prev, [service.id]: false }));
        }
      }
    };

    checkHealth();
    const interval = setInterval(checkHealth, 5000);
    return () => clearInterval(interval);
  }, []);

  return (
    <>
      <header>
        <h1>MedFlow Enterprise</h1>
        <h2>Architected & Deployed by <strong>Gopall Chennu</strong></h2>
      </header>

      <main className="glass-grid">
        {initialMicroservices.map((service) => {
          const isOnline = statuses[service.id] !== false; // Default to online until checked
          return (
            <div key={service.id} className={`glass-card ${!isOnline ? 'offline' : ''}`}>
              <h3>{service.icon} {service.name}</h3>
              <p>{service.description}</p>
              <span className={`status-badge ${isOnline ? 'status-online' : 'status-offline'}`}>
                {isOnline ? '● Online' : '● Offline'}
              </span>
            </div>
          );
        })}
      </main>

      <footer className="footer">
        <p>MedFlow System Status: All Systems Operational | Current Time: {currentTime}</p>
        <p>Copyright © {new Date().getFullYear()} Gopall Chennu. All rights reserved.</p>
      </footer>
    </>
  );
}

export default App;
