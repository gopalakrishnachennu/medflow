import React, { useState, useEffect } from 'react';

// Mock data representing the 7 microservices
const microservices = [
  { name: 'Auth Service', description: 'Handles JWT Authentication & User Management', icon: '🔒' },
  { name: 'Patient Service', description: 'Patient Electronic Health Records & Profiles', icon: '🏥' },
  { name: 'Appointment Service', description: 'Scheduling and Calendar Management', icon: '📅' },
  { name: 'Records Service', description: 'Medical History and Diagnostics Storage', icon: '📂' },
  { name: 'Pharmacy Service', description: 'Prescription Management and Inventory', icon: '💊' },
  { name: 'Billing Service', description: 'Invoicing, Insurance, and Payments', icon: '💳' },
  { name: 'Notification Service', description: 'Email and SMS Patient Alerts', icon: '🔔' },
];

function App() {
  const [currentTime, setCurrentTime] = useState(new Date().toLocaleTimeString());

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date().toLocaleTimeString());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  return (
    <>
      <header>
        <h1>MedFlow Enterprise</h1>
        <h2>Architected & Deployed by <strong>Gopall Chennu</strong></h2>
      </header>

      <main className="glass-grid">
        {microservices.map((service, index) => (
          <div key={index} className="glass-card">
            <h3>{service.icon} {service.name}</h3>
            <p>{service.description}</p>
            <span className="status-badge status-online">● Online</span>
          </div>
        ))}
      </main>

      <footer className="footer">
        <p>MedFlow System Status: All Systems Operational | Current Time: {currentTime}</p>
        <p>Copyright © {new Date().getFullYear()} Gopall Chennu. All rights reserved.</p>
      </footer>
    </>
  );
}

export default App;
