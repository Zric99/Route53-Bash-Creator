import React from 'react';

export default function RecordPreview({ values }) {
  if (!values) return null;
  return (
    <div style={{
      marginTop: 32,
      padding: 24,
      borderRadius: 12,
      background: 'linear-gradient(90deg, #e3f0ff 0%, #f8faff 100%)',
      boxShadow: '0 2px 8px rgba(0,0,0,0.07)',
      fontFamily: 'Inter, Arial, sans-serif',
      color: '#222',
    }}>
      <h2 style={{marginBottom: 16}}>Preview: DNS Record</h2>
      <div><strong>Record Name:</strong> {values.recordName}</div>
      <div><strong>Target DNS:</strong> {values.targetDns}</div>
      <div><strong>Customer DNS:</strong> {values.customerDns}</div>
      <div><strong>Type:</strong> {values.type}</div>
      <div><strong>TTL:</strong> {values.ttl}</div>
      <div><strong>Zone ID:</strong> {values.zoneId}</div>
      <div style={{marginTop: 16, fontSize: 13, color: '#666'}}>
        Please check all values before creating the record.
      </div>
    </div>
  );
}
