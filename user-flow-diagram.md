# Callab User Flow Diagrams

## Main User Flows

```mermaid
flowchart TD
    Start([User Arrives]) --> Auth{Authenticated?}

    Auth -->|No| Landing[Landing Page]
    Auth -->|Yes| Dashboard[Dashboard]

    Landing --> LoginChoice{Choose Action}
    LoginChoice -->|New User| Signup[Sign Up Page]
    LoginChoice -->|Existing User| Login[Login Page]
    LoginChoice -->|Public Link| PublicCal[Public Booking Page]

    Signup --> SignupMethod{Sign Up Method}
    SignupMethod -->|Email/Password| EmailSignup[Register Form]
    SignupMethod -->|Google OAuth| GoogleAuth[Google OAuth]

    EmailSignup --> EmailVerify[Email Verification Notice]
    GoogleAuth --> Dashboard
    EmailVerify --> Dashboard

    Login --> LoginMethod{Login Method}
    LoginMethod -->|Email/Password| EmailLogin[Login Form]
    LoginMethod -->|Google OAuth| GoogleAuth
    LoginMethod -->|Forgot Password| ForgotPW[Password Reset]

    EmailLogin --> Dashboard
    ForgotPW --> ResetEmail[Check Email]
    ResetEmail --> ResetForm[Reset Password Form]
    ResetForm --> Login

    Dashboard --> NavChoice{User Action}

    NavChoice -->|Calendars| CalendarList[Calendar List]
    NavChoice -->|Events| EventList[Event List]
    NavChoice -->|Clients| ClientList[Client List]
    NavChoice -->|Notes| NoteList[Notes List]
    NavChoice -->|AI Assistant| AIChat[AI Chat Interface]
    NavChoice -->|Settings| Settings[Settings Page]

    style AIChat fill:#4f46e5,stroke:#333,stroke-width:4px,color:#fff
    style Dashboard fill:#10b981,stroke:#333,stroke-width:2px,color:#fff
    style PublicCal fill:#f59e0b,stroke:#333,stroke-width:2px
```

## AI Assistant Flow (Core Feature)

```mermaid
flowchart TD
    Start([User Opens AI Chat]) --> ChatEmpty{First Time?}

    ChatEmpty -->|Yes| ShowExamples[Show Example Prompts]
    ChatEmpty -->|No| ShowHistory[Show Chat History]

    ShowExamples --> UserInput[User Types/Speaks Request]
    ShowHistory --> UserInput

    UserInput --> AIProcess[AI Processes Request]

    AIProcess --> AIAction{AI Determines Action}

    AIAction -->|Needs Context| SearchNotes[Search User Notes]
    AIAction -->|Check Schedule| ListAvailability[Query Calendar Availability]
    AIAction -->|Find Contact| FindClient[Find/Create Client]
    AIAction -->|Book Meeting| CreateEvent[Create Event]
    AIAction -->|Unclear| AskClarification[Ask User for Details]

    SearchNotes --> AIRespond[AI Generates Response]
    ListAvailability --> AIRespond
    FindClient --> AIRespond
    AskClarification --> QuickReplies[Show Quick Reply Buttons]
    QuickReplies --> UserInput

    CreateEvent --> ConflictCheck{Event Conflicts?}
    ConflictCheck -->|Yes| ConflictWarn[Warn User of Overlap]
    ConflictCheck -->|No| EventCreated[Event Created Successfully]

    ConflictWarn --> AskOverride{User Confirms?}
    AskOverride -->|Yes| EventCreated
    AskOverride -->|No| AIRespond

    EventCreated --> ShowEventCard[Display Event Confirmation Card]
    ShowEventCard --> AIRespond

    AIRespond --> MoreActions{User Continues?}
    MoreActions -->|Yes| UserInput
    MoreActions -->|No| End([Chat Complete])

    style AIProcess fill:#4f46e5,stroke:#333,stroke-width:2px,color:#fff
    style EventCreated fill:#10b981,stroke:#333,stroke-width:2px,color:#fff
    style ConflictWarn fill:#ef4444,stroke:#333,stroke-width:2px,color:#fff
```

## Event Management Flow

```mermaid
flowchart TD
    Start([Event Management]) --> EventView{View Type}

    EventView -->|List View| EventList[Event List/Calendar Grid]
    EventView -->|Create New| CreateEvent[Click 'New Event']

    EventList --> EventAction{User Action}
    EventAction -->|View Details| EventDetail[Event Detail View]
    EventAction -->|Edit| EditEvent[Edit Event Modal]
    EventAction -->|Delete| DeleteConfirm[Confirm Delete]
    EventAction -->|Create New| CreateEvent

    CreateEvent --> EventForm[Event Form Modal]
    EditEvent --> EventForm

    EventForm --> FormFields[Fill Event Details]
    FormFields --> SelectClient{Select Client}

    SelectClient -->|Existing| ChooseClient[Choose from Dropdown]
    SelectClient -->|New| CreateClient[Create New Client]

    CreateClient --> ClientForm[Quick Client Form]
    ClientForm --> ClientNormalize[Auto-Normalize Email/Phone]
    ClientNormalize --> ClientSaved[Client Saved]
    ClientSaved --> ChooseClient

    ChooseClient --> SelectCalendar[Select Calendar]
    SelectCalendar --> SelectDateTime[Choose Date/Time]
    SelectDateTime --> ConflictCheck{Check Conflicts}

    ConflictCheck -->|Overlap Detected| ShowWarning[Show Conflict Warning]
    ConflictCheck -->|No Conflicts| SaveEvent[Save Event]

    ShowWarning --> UserDecision{User Decides}
    UserDecision -->|Adjust Time| SelectDateTime
    UserDecision -->|Force Save| SaveEvent
    UserDecision -->|Cancel| EventList

    SaveEvent --> SendNotifications{Notifications Enabled?}
    SendNotifications -->|Yes| SendEmailSMS[Send Email/SMS to Client]
    SendNotifications -->|No| EventSaved[Event Saved]
    SendEmailSMS --> EventSaved

    EventSaved --> EventDetail
    EventDetail --> BackToList[Back to Event List]
    DeleteConfirm --> EventDeleted[Event Deleted]
    EventDeleted --> EventList

    style SaveEvent fill:#10b981,stroke:#333,stroke-width:2px,color:#fff
    style ShowWarning fill:#ef4444,stroke:#333,stroke-width:2px,color:#fff
    style ClientNormalize fill:#f59e0b,stroke:#333,stroke-width:2px
```

## Public Calendar Booking Flow (No Auth)

```mermaid
flowchart TD
    Start([User Clicks Public Link]) --> LoadPublic[Load Public Booking Page]

    LoadPublic --> ShowCalendar[Show Calendar Owner Info]
    ShowCalendar --> SelectDate[User Selects Date]

    SelectDate --> FetchAvailability[Fetch Available Time Slots]
    FetchAvailability --> ShowSlots[Display Available Times]

    ShowSlots --> SlotChoice{User Action}
    SlotChoice -->|Select Time| ShowBookingForm[Show Booking Form]
    SlotChoice -->|Change Date| SelectDate

    ShowBookingForm --> FillInfo[Enter Name/Email/Phone]
    FillInfo --> AddMessage[Optional Message]
    AddMessage --> SubmitBooking[Click 'Confirm Booking']

    SubmitBooking --> Normalize[Auto-Normalize Contact Info]
    Normalize --> CreateClient[Create/Update Client Record]
    CreateClient --> CreateEvent[Create Event in Calendar]

    CreateEvent --> ConflictCheck{Still Available?}
    ConflictCheck -->|No - Booked| ShowError[Show 'Time No Longer Available']
    ConflictCheck -->|Yes| EventCreated[Event Created]

    ShowError --> ShowSlots

    EventCreated --> SendConfirmation[Send Confirmation Email/SMS]
    SendConfirmation --> ShowSuccess[Show Success Page]

    ShowSuccess --> SuccessOptions{User Action}
    SuccessOptions -->|Download ICS| DownloadCalendar[Download .ics File]
    SuccessOptions -->|Book Another| SelectDate
    SuccessOptions -->|Done| End([Booking Complete])

    DownloadCalendar --> End

    style EventCreated fill:#10b981,stroke:#333,stroke-width:2px,color:#fff
    style ShowError fill:#ef4444,stroke:#333,stroke-width:2px,color:#fff
    style Normalize fill:#f59e0b,stroke:#333,stroke-width:2px
```

## Calendar Management Flow

```mermaid
flowchart TD
    Start([Calendar Section]) --> CalList[View Calendar List]

    CalList --> CalAction{User Action}

    CalAction -->|Create New| CreateCal[Click 'New Calendar']
    CalAction -->|View Calendar| CalDetail[Calendar Detail View]
    CalAction -->|Edit| EditCal[Edit Calendar]
    CalAction -->|Delete| DeleteCal[Delete Calendar]
    CalAction -->|Share| ShareCal[Share Calendar]

    CreateCal --> CalForm[Calendar Form]
    EditCal --> CalForm

    CalForm --> FillCalInfo[Enter Name/Timezone]
    FillCalInfo --> SaveCal[Save Calendar]
    SaveCal --> CalDetail

    ShareCal --> TogglePublic{Enable Public Booking?}
    TogglePublic -->|Yes| GenerateToken[Generate Public Token]
    TogglePublic -->|No| DisablePublic[Disable Public Access]

    GenerateToken --> ShowPublicLink[Display Public Link]
    ShowPublicLink --> CopyLink[Copy Link Button]
    CopyLink --> LinkCopied[Link Copied to Clipboard]
    DisablePublic --> CalDetail
    LinkCopied --> CalDetail

    CalDetail --> DetailAction{View Action}
    DetailAction -->|View Events| EventGrid[Calendar Grid with Events]
    DetailAction -->|Check Availability| AvailCheck[Availability Checker]
    DetailAction -->|Back| CalList

    EventGrid --> EventInteraction[Click Event to View/Edit]
    EventInteraction --> EventDetail[Event Detail Page]

    AvailCheck --> SelectDateRange[Select Date Range]
    SelectDateRange --> ShowAvailability[Display Free Time Slots]
    ShowAvailability --> CalDetail

    DeleteCal --> ConfirmDelete{Confirm Deletion?}
    ConfirmDelete -->|Yes| CalDeleted[Calendar Deleted]
    ConfirmDelete -->|No| CalList
    CalDeleted --> CalList

    style GenerateToken fill:#f59e0b,stroke:#333,stroke-width:2px
    style SaveCal fill:#10b981,stroke:#333,stroke-width:2px,color:#fff
    style CalDeleted fill:#ef4444,stroke:#333,stroke-width:2px,color:#fff
```

## Notes & Preferences Flow

```mermaid
flowchart TD
    Start([Notes Section]) --> NoteList[View Notes List]

    NoteList --> NoteAction{User Action}

    NoteAction -->|Create Note| CreateNote[Click 'New Note']
    NoteAction -->|View Note| ViewNote[Note Detail]
    NoteAction -->|Edit Note| EditNote[Edit Note]
    NoteAction -->|Delete Note| DeleteNote[Delete Note]
    NoteAction -->|Search Notes| SearchNotes[Semantic Search]

    CreateNote --> NoteForm[Note Editor]
    EditNote --> NoteForm

    NoteForm --> WriteContent[Write Note Content]
    WriteContent --> AutoSave[Auto-Save Note]

    AutoSave --> GenerateEmbedding[Generate Vector Embedding]
    GenerateEmbedding --> EmbeddingProcess[Ollama Creates 768-dim Vector]
    EmbeddingProcess --> SaveWithVector[Save Note + Embedding]

    SaveWithVector --> NoteSaved[Note Saved Successfully]
    NoteSaved --> ViewNote

    ViewNote --> BackToList[Back to Notes List]
    BackToList --> NoteList

    SearchNotes --> EnterQuery[Enter Search Query]
    EnterQuery --> VectorSearch[Semantic Vector Search]

    VectorSearch --> CosineSimilarity[Calculate Cosine Similarity]
    CosineSimilarity --> RankResults[Rank by Relevance]
    RankResults --> ShowResults[Display Results with Scores]

    ShowResults --> ResultAction{User Action}
    ResultAction -->|View Note| ViewNote
    ResultAction -->|New Search| EnterQuery
    ResultAction -->|Back| NoteList

    DeleteNote --> ConfirmDelete{Confirm?}
    ConfirmDelete -->|Yes| NoteDeleted[Note Deleted]
    ConfirmDelete -->|No| NoteList
    NoteDeleted --> NoteList

    style GenerateEmbedding fill:#4f46e5,stroke:#333,stroke-width:2px,color:#fff
    style VectorSearch fill:#4f46e5,stroke:#333,stroke-width:2px,color:#fff
    style NoteSaved fill:#10b981,stroke:#333,stroke-width:2px,color:#fff
```

## Complete System Architecture Flow

```mermaid
flowchart LR
    User([User]) --> Frontend[Web Frontend]
    Public([Public Booker]) --> Frontend

    Frontend --> API[Rails API]

    API --> Auth{Authentication}
    Auth -->|JWT| AuthService[JWT Service]
    Auth -->|OAuth| GoogleOAuth[Google OAuth]

    API --> Controllers{Controllers}

    Controllers --> CalCtrl[Calendars Controller]
    Controllers --> EventCtrl[Events Controller]
    Controllers --> ClientCtrl[Clients Controller]
    Controllers --> NoteCtrl[Notes Controller]
    Controllers --> AICtrl[AI Controller]

    CalCtrl --> DB[(PostgreSQL + pgvector)]
    EventCtrl --> DB
    ClientCtrl --> DB
    NoteCtrl --> DB

    NoteCtrl --> Ollama[Ollama Embeddings]
    Ollama --> VectorDB[pgvector Store]
    VectorDB --> DB

    AICtrl --> Claude[Claude Sonnet 4.5]
    Claude --> RAG[RAG System]
    RAG --> VectorDB

    Claude --> Tools{AI Tools}
    Tools --> SearchNotes[search_notes]
    Tools --> ListAvail[list_availability]
    Tools --> FindClient[find_or_create_client]
    Tools --> CreateEvt[create_event]

    SearchNotes --> VectorDB
    ListAvail --> DB
    FindClient --> DB
    CreateEvt --> DB

    EventCtrl --> Notifications[Notification Service]
    Notifications --> Email[Email via ActionMailer]
    Notifications --> SMS[SMS via Twilio]

    Email --> ClientEmail([Client Email])
    SMS --> ClientPhone([Client Phone])

    style Claude fill:#4f46e5,stroke:#333,stroke-width:4px,color:#fff
    style RAG fill:#4f46e5,stroke:#333,stroke-width:2px,color:#fff
    style DB fill:#10b981,stroke:#333,stroke-width:2px,color:#fff
    style VectorDB fill:#8b5cf6,stroke:#333,stroke-width:2px,color:#fff
```

---

## How to View These Diagrams

1. **In GitHub**: These will render automatically if you push this file to GitHub
2. **In VS Code**: Install the "Markdown Preview Mermaid Support" extension
3. **Online**: Copy and paste into [Mermaid Live Editor](https://mermaid.live)
4. **In Figma**: Use the "Mermaid Chart" plugin to import these diagrams

## Diagram Descriptions

- **Main User Flows**: Overall navigation and authentication paths
- **AI Assistant Flow**: Detailed interaction with the Claude AI assistant
- **Event Management Flow**: Creating, editing, and managing events
- **Public Calendar Booking Flow**: External user booking without authentication
- **Calendar Management Flow**: Managing multiple calendars and sharing
- **Notes & Preferences Flow**: Creating notes with semantic search
- **System Architecture Flow**: Technical overview of system components

