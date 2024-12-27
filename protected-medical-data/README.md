# Personalized Medicine Smart Contract

## Overview
This smart contract implements a decentralized healthcare records and prescription management system on the Stacks blockchain. It enables secure handling of patient medical records, healthcare provider credentials, and prescription management with proper access controls and authorization mechanisms.

## Features
- Patient health record management
- Healthcare provider registration and verification
- Prescription creation and management
- Authorization system for provider access
- Input validation for data integrity
- Active prescription tracking
- Secure medical data storage

## Contract Components

### 1. Patient Management
- Register new patients with medical history and DNA sequencing data
- Maintain comprehensive health records
- Authorize healthcare providers for access
- View personal medical information

### 2. Healthcare Provider Management
- Provider registration with specialty and license information
- Credential verification system
- Active status tracking
- Provider profile management

### 3. Prescription System
- Create new prescriptions
- Track prescription validity periods
- Manage active/inactive prescription status
- Record medication details and dosage instructions

## Technical Specifications

### Storage Maps
1. `patient-health-records`:
   - Stores patient medical histories
   - Tracks authorized providers
   - Maintains active medication lists
   - Maximum 5 authorized providers per patient

2. `medical-provider-directory`:
   - Stores provider credentials
   - Tracks medical specialties
   - Maintains license information
   - Verifies provider status

3. `medication-prescriptions`:
   - Records prescription details
   - Tracks validity periods
   - Manages prescription status
   - Links patients with providers

### Constants and Limitations
- Maximum 5 authorized providers per patient
- Maximum 10 active prescriptions per patient
- Maximum 100 prescriptions in the tracking list
- String length limitations:
  - Long text: 256 characters
  - Medium text: 64 characters
  - Short text: 32 characters

## Usage Guide

### For Patients

1. Registration:
```clarity
(contract-call? .personalized-medicine register-patient 
    "Patient medical history" 
    "DNA sequencing data")
```

2. Authorize Provider:
```clarity
(contract-call? .personalized-medicine authorize-medical-provider 
    'PROVIDER_ADDRESS)
```

3. View Health Record:
```clarity
(contract-call? .personalized-medicine get-patient-health-record 
    'PATIENT_ADDRESS)
```

### For Healthcare Providers

1. Provider Registration:
```clarity
(contract-call? .personalized-medicine register-medical-provider 
    "Cardiology" 
    "MD123456")
```

2. Create Prescription:
```clarity
(contract-call? .personalized-medicine create-prescription
    'PATIENT_ADDRESS
    "Medication Name"
    "1 pill twice daily"
    u1640995200  ;; start timestamp
    u1643673600) ;; end timestamp
```

3. Deactivate Prescription:
```clarity
(contract-call? .personalized-medicine deactivate-prescription
    u1)  ;; prescription-unique-id
```

## Error Codes
- `ERR-UNAUTHORIZED-ACCESS (u1)`: Attempted access without proper authorization
- `ERR-DUPLICATE-PATIENT-RECORD (u2)`: Patient already registered
- `ERR-PATIENT-RECORD-NOT-FOUND (u3)`: Referenced patient doesn't exist
- `ERR-INVALID-PRESCRIPTION-DATA (u4)`: Invalid prescription parameters
- `ERR-DUPLICATE-HEALTHCARE-PROVIDER (u5)`: Provider already registered
- `ERR-HEALTHCARE-PROVIDER-NOT-FOUND (u6)`: Referenced provider doesn't exist
- `ERR-PRESCRIPTION-LIST-OVERFLOW (u7)`: Exceeded maximum prescription list size
- `ERR-INVALID-INPUT (u8)`: Invalid input parameters
- `ERR-PROVIDER-ALREADY-AUTHORIZED (u9)`: Provider already authorized
- `ERR-MAX-AUTHORIZED-PROVIDERS-REACHED (u10)`: Maximum provider limit reached

## Security Considerations

1. Access Control:
   - Only authorized providers can access patient records
   - Patients control provider authorization
   - Only authorized providers can create prescriptions
   - Only the prescribing provider or patient can deactivate prescriptions

2. Data Validation:
   - All string inputs are validated for length and format
   - Prescription dates are validated for proper ordering
   - Provider credentials are verified before operations

3. Storage Limitations:
   - Fixed list sizes prevent denial-of-service attacks
   - Strict input length validation
   - Maximum limits on authorized providers and prescriptions

## Best Practices for Implementation

1. Always verify provider authorization before accessing patient data
2. Regularly verify provider credentials
3. Implement proper error handling for all contract calls
4. Maintain accurate timestamps for prescription validity
5. Keep provider authorization lists updated
6. Regularly check prescription status and validity

## Note on Privacy
While this contract implements access controls, all data stored on the blockchain is public. Sensitive medical information should be stored off-chain with only references and access controls managed by this contract.