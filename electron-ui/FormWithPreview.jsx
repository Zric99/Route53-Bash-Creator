import React, { useState } from 'react';
import RecordPreview from './RecordPreview';

export default function FormWithPreview() {
  const [form, setForm] = useState({
    recordName: '',
    targetDns: '',
    customerDns: '',
    type: 'A',
    ttl: 300,
    zoneId: '',
  });

  const handleChange = e => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  return (
    <div style={{ maxWidth: 500, margin: '0 auto', padding: 32 }}>
      <h1 style={{marginBottom: 24}}>Create Route53 Record</h1>
      <input name="recordName" placeholder="Record Name" value={form.recordName} onChange={handleChange} style={{width:'100%',marginBottom:12}} />
      <input name="targetDns" placeholder="Target DNS" value={form.targetDns} onChange={handleChange} style={{width:'100%',marginBottom:12}} />
      <input name="customerDns" placeholder="Customer DNS" value={form.customerDns} onChange={handleChange} style={{width:'100%',marginBottom:12}} />
      <input name="type" placeholder="Type" value={form.type} onChange={handleChange} style={{width:'100%',marginBottom:12}} />
      <input name="ttl" placeholder="TTL" type="number" value={form.ttl} onChange={handleChange} style={{width:'100%',marginBottom:12}} />
      <input name="zoneId" placeholder="Zone ID" value={form.zoneId} onChange={handleChange} style={{width:'100%',marginBottom:12}} />
      {/* Preview below */}
      <RecordPreview values={form} />
      <button style={{marginTop:24,padding:'12px 32px',fontSize:16,borderRadius:8,background:'#0078ff',color:'#fff',border:'none',cursor:'pointer'}}>Create Record</button>
    </div>
  );
}
