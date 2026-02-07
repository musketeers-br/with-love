 [![Gitter](https://img.shields.io/badge/Available%20on-Intersystems%20Open%20Exchange-00b2a9.svg)](https://openexchange.intersystems.com/package/intersystems-iris-dev-template)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat&logo=AdGuard)](LICENSE)
[![InterSystems IRIS](https://img.shields.io/badge/InterSystems-IRIS%20for%20Health-blue.svg)](https://www.intersystems.com/products/intersystems-iris-for-health/)
[![FHIR R4](https://img.shields.io/badge/FHIR-R4-orange.svg)](https://www.hl7.org/fhir/)

![withLove Banner](./assets/withlove-banner.png)

# 💜 withLove

**The First Self-Driving Platform for InterSystems IRIS Health**

> *Vibe-code your healthcare infrastructure — IRIS-native, FHIR-compliant, delightfully fast.*

---

## 🚀 Motivation

Building healthcare applications is **hard**. Creating FHIR APIs, integrating legacy systems (HL7v2), managing multi-tenant databases, and maintaining interoperability workflows requires months of development and deep expertise in InterSystems IRIS for Health.

**withLove changes everything.**

It's the first **"loveable"** (delightful + powerful) platform that lets hospitals, clinics, EHR vendors, and healthtech ISVs create:
- ✅ **FHIR R4-compliant REST APIs** in seconds
- ✅ **Multi-tenant persistent classes** (SQL tables) automatically
- ✅ **Interoperability workflows** (HL7, DTL, Business Operations) via natural language
- ✅ **Admin UIs** (CRUD interfaces) with modern frameworks (Tailwind/Alpine.js)
- ✅ **RAG-powered knowledge base** for protocol-driven development

All through a **conversational AI interface** — just describe what you need in plain language, and withLove builds it for you.

---

## 🛠️ How It Works

withLove utilizes a **multi-agent architecture** powered by cutting-edge technologies:

### **Core Technologies**

1. **InterSystems IRIS for Health**  
   High-performance healthcare data platform with native FHIR, and HL7v2 support.

2. **Multi-Agent AI System**  
   - **UI Agent**: Generates responsive frontends (Tailwind CSS + Alpine.js)
   - **Backend Agent**: Creates persistent classes (multi-tenant SQL tables)
   - **API Agent**: Builds REST APIs with dynamic routing
   - **Interop Agent**: Generates DTL transformations and Business Operations
   - **Knowledge Agent**: RAG-powered document search (384-dim vectors)
   - **Scanner Agent**: Analyzes brownfield code and suggests modernization paths

3. **LLM Integration**  
   Supports OpenAI ChatGPT, Google Gemini and Anthropic (Claude) via flexible API key configuration.

4. **FHIR R4 Native**  
   Full compliance with HL7 FHIR R4 standard, including Bundle validation and SDA3 transformation.

### **Architecture Overview**

```
┌─────────────────────────────────────────────────────────────┐
│                    User (Chat Interface)                    │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              GenAi.AgentRun() (Orchestrator)                │
│  - Intent Detection (CREATE_API, CREATE_TABLE, SCAN, etc)  │
│  - Delegates to specialized factories                       │
└─────────────────────────┬───────────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         ▼                ▼                ▼
┌─────────────────┐ ┌─────────────┐ ┌──────────────────┐
│   AppFactory    │ │ ApiFactory  │ │ ClassFactory     │
│ (UI Generator)  │ │(API Gen)    │ │(DB Tables)       │
└─────────────────┘ └─────────────┘ └──────────────────┘
         │                │                │
         └────────────────┼────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│        Multi-Tenant Deployment (dc.withLove.<tenant>)       │
│  - .apps (CSP Pages)                                        │
│  - .api (REST Services)                                     │
│  - .data (Persistent Classes)                               │
│  - .interop (DTL/BO/BS)                                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Prerequisites

- **Docker** and **Docker Compose** installed on your machine
- **API Key** for LLM provider:
  - OpenAI API Key (`sk-...`) **or**
  - Anthropic API Key (`sk-ant-...`)
- **Minimum 8GB RAM** (16GB recommended for production)
- **10GB free disk space** (FHIR Server installation requires additional storage)

---

## 🛠️ Installation

### 1. **Clone the Repository**
```sh
git clone https://github.com/your-org/withLove.git
cd withLove
```

### 2. **Build the Docker Container**

```sh
docker-compose build --no-cache --progress=plain
```

### 4. **Start the Application**

```sh
docker-compose up -d
```

### 5. **Wait for IRIS Startup**

```sh
docker-compose logs -f iris
```

Wait until you see logs like:

```bash
withlove-iris-1  | [INFO] ...started InterSystems IRIS instance IRIS
withlove-iris-1  | [INFO] Installing FHIR Server (ZPM)...
withlove-iris-1  | [INFO] This may take several minutes...
withlove-iris-1  | [INFO] FHIR Server installed successfully
withlove-iris-1  | [INFO] withLove is ready!
```

> **⚠️ Important Note:**  
> This project automatically installs the **FHIR Server** via ZPM (`zpm "install fhir-server"`), which can take **5-15 minutes** depending on your network speed and machine specs. Please be patient during the first startup.

You can also check the [Management Portal](http://localhost:52773/csp/sys/UtilHome.csp) (user: `_system`, password: `SYS`) to verify installation status.

---

## 💡 How to Use

Once withLove is running, access the **Chat Interface**:

🌐 **Frontend:** [http://localhost:8080](http://localhost:8080)

### **Example 1: Create a FHIR Patient API**

```
💬 You: "Create a FHIR R4 API for managing patients with CPF validation"

🤖 withLove: 
✅ Detected: HS.SDA3.Patient (50,000 records)
✅ Generating CRUD endpoints:
   - GET /fhir/Patient
   - GET /fhir/Patient/:id
   - POST /fhir/Patient
   - PUT /fhir/Patient/:id

✅ Adding validations:
   - CPF format validator
   - Active status check

✅ Deploying to: /withlove/services/hospital-main/PatientAPI

[✅ Approve] [✏️ Adjust] [❌ Cancel]
```

**Click "Approve"** → API is live in seconds!

Test it:
```bash
curl -X GET http://localhost:52773/withlove/services/hospital-main/PatientAPI/list \
  -H "X-Tenant-ID: hospital-main" \
  -H "Authorization: Bearer your-api-key"
```

---

### **Example 2: Generate a Database Table**

```
💬 You: "Create a table for Dengue cases with fields: PatientID, Symptoms, TestDate, Result"

🤖 withLove:
✅ Generating persistent class: dc.withLove.hospital-main.data.DengueCase
✅ Fields:
   - PatientID (String, indexed)
   - Symptoms (String, MAXLEN="")
   - TestDate (Date)
   - Result (String: Positive/Negative/Pending)
✅ Compiled successfully
✅ Table available: dc_withLove_hospital_main_data.DengueCase

[✅ Approve]
```

---

### **Example 3: Create an HL7 Integration**

```
💬 You: "Create a DTL to transform HL7 ADT^A04 messages into SDA3.Patient"

🤖 withLove:
✅ Generating DTL: dc.withLove.hospital-main.interop.ADTToPatient
✅ Source: EnsLib.HL7.Message (ADT_A04)
✅ Target: HS.SDA3.Patient
✅ Mappings:
   - PID:PatientName → Patient.Name
   - PID:PatientID → Patient.PatientNumbers
   - PID:DOB → Patient.BirthTime
✅ Compiled successfully

[✅ Approve]
```

---

### **Example 4: Scan Brownfield System**

```
💬 You: "Scan my system and suggest APIs to create"

🤖 withLove:
🔍 Scanning namespace: HSREGISTRY
✅ Found 127 classes (47 SDA3, 80 custom)

📊 Top Entities by Volume:
1. HS.SDA3.Patient (12.5M records) ⭐ Suggest: GET /fhir/Patient
2. HS.SDA3.Encounter (45M records) ⭐ Suggest: GET /fhir/Encounter
3. Custom.Lab.Result (22M) ⚠️ Not FHIR-compliant (suggest migration)

⚠️ Issues Detected:
- HS.SDA3.Encounter: Missing index on PatientID (slow queries >500ms)
- Custom.Patient.Insurance: No tenant isolation (security risk)

[✨ Create All APIs] [📋 View Details]
```

---

### **Example 5: Add Knowledge to RAG**

**Upload Protocol:**
```bash
curl -X POST http://localhost:52773/api/knowledge/add \
  -H "Content-Type: application/json" \
  -H "X-Tenant-ID: hospital-main" \
  -d '{
    "title": "Dengue Treatment Protocol 2026",
    "content": "Treatment guidelines for dengue patients..."
  }'
```

**Query with Context:**
```
💬 You: "How should I treat a dengue patient according to our protocol?"

🤖 withLove:
📚 Found relevant document: "Dengue Treatment Protocol 2026"

According to your protocol:
1. Immediate hydration (IV fluids)
2. Monitor platelet count every 6 hours
3. Administer paracetamol for fever (avoid NSAIDs)
...
```

---

## 🎨 Advanced Features

### **Dashboard Cockpit** (Coming Soon - v1.0)

Access your command center at [http://localhost:8080/dashboard.html](http://localhost:8080/dashboard.html)

- 📊 **KPIs**: Apps, APIs, Tables, Interop components, RAG documents
- 📈 **Analytics**: Activity trends (last 7 days)
- 🔗 **Quick Links**: Open apps, test APIs, view database schemas
- ⚡ **One-Click Actions**: Deploy, delete, export configurations

---

## 🗂️ Project Structure

```
withLove/
├── src/
│   ├── dc/
│   │   └── withLove/
│   │       ├── engine/          # Core AI Factories
│   │       │   ├── GenAi.cls    # LLM Orchestrator
│   │       │   ├── AppFactory.cls
│   │       │   ├── ApiFactory.cls
│   │       │   ├── ClassFactory.cls
│   │       │   └── InteropFactory.cls
│   │       ├── service/         # Business Logic
│   │       │   ├── Dispatch.cls # REST API Router
│   │       │   ├── KnowledgeService.cls
│   │       │   ├── ScannerService.cls
│   │       │   └── RestRouter.cls
│   │       └── storage/         # Data Models
│   │           ├── Project.cls
│   │           ├── AppVersion.cls
│   │           ├── Tenant.cls
│   │           ├── LLMSession.cls
│   │           └── KnowledgeBase.cls
├── static/
│   ├── index.html              # Chat Interface
│   ├── dashboard.html          # Admin Dashboard (v1.0)
│   └── assets/
│       ├── css/
│       └── js/
├── docker-compose.yml
├── Dockerfile
├── .env.example
└── README.md
```

---

## 🔌 API Reference

### **Core Endpoints**

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/agent/chat` | POST | Conversational agent (main interface) |
| `/api/deploy` | POST | Deploy generated assets |
| `/api/knowledge/add` | POST | Add document to RAG |
| `/api/knowledge/list` | GET | List RAG documents |
| `/api/scan/list` | GET | List brownfield assets |
| `/api/scan/analyze` | POST | Analyze asset with AI |
| `/api/dashboard/summary` | GET | Get dashboard metrics |

### **Dynamic Service Endpoints**

Generated APIs follow the pattern:

```
/withlove/services/<tenant>/<service-name>/*
```

Example:
```
GET /withlove/services/hospital-main/PatientAPI/list
POST /withlove/services/hospital-main/PatientAPI/create
PUT /withlove/services/hospital-main/PatientAPI/update/:id
```

---

## 🧪 Testing

### **Using Postman**

Import the collection: [`postman/withLove.postman_collection.json`](./postman/withLove.postman_collection.json)

### **Using cURL**

**Chat Example:**
```bash
curl -X POST http://localhost:52773/api/agent/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-your-key" \
  -H "X-Tenant-ID: hospital-main" \
  -d '{
    "sessionId": "session-123",
    "prompt": "Create an API for patients",
    "model": "gpt-4o"
  }'
```

---

## 📊 Roadmap

### ✅ **v0.9 MVP (Done)**
- [x] UI Agent (App generation)
- [x] Backend Agent (Class generation)
- [x] API Agent (REST API generation)
- [x] Interop Agent (DTL/BO generation)
- [x] RAG Knowledge Base
- [x] Brownfield Scanner

### 🚧 **v1.0 Gold (Current)**
- [ ] Complete `GenAi.cls` implementation
- [ ] Dashboard Cockpit
- [ ] End-to-end testing
- [ ] Documentation

### 🔮 **v1.1 (Planned)**
- [ ] Analytics Agent (BI dashboards)
- [ ] Approval workflow (multi-stakeholder)
- [ ] Swagger UI auto-generation
- [ ] Performance optimizations

### 🌟 **v2.0 (Future)**
- [ ] Visual workflow builder (Node-RED style)
- [ ] Low-code UI builder (drag-and-drop)
- [ ] Template marketplace
- [ ] Multi-language support

---

## 🎖️ Credits

`withLove` is developed with 💜 by the **Musketeers Team**:

- [José Roberto Pereira](https://community.intersystems.com/user/jos%C3%A9-roberto-pereira-0)
- [Henry Pereira](https://community.intersystems.com/user/henry-pereira)
- [Henrique Dias](https://community.intersystems.com/user/henrique-dias-2)

![3Musketeers-br](./assets/3musketeers.png)

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---


## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/musketeers-br/with-love/issues)
- **Discussions**: [GitHub Discussions](https://github.com/musketeers-br/with-love/discussions)
- **Community**: [InterSystems Developer Community](https://community.intersystems.com/)

---

## 🌟 Star History

If you find withLove helpful, please consider giving it a ⭐ on GitHub!

---

**Made with 💜 for the healthcare community**


> **⚠️ Important Note:**  
> This project automatically installs the **FHIR Server** via ZPM (`zpm "install fhir-server"`), which can take **5-15 minutes** depending on your network speed and machine specs. Please be patient during the first startup.
