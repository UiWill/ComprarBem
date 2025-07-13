# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

- **Serve in development**: `npm run serve`
- **Build for production**: `npm run build`
- **Lint code**: `npm run lint`
- **Deploy to GitHub Pages**: `npm run deploy`

## Project Architecture

### Technology Stack
- **Frontend**: Vue.js 2.7.16 with Vue Router and Vuex
- **Backend/Database**: Supabase (PostgreSQL with real-time capabilities)
- **AI Integration**: Google Gemini API with fallback system
- **Build Tool**: Vue CLI 5.0
- **Deployment**: GitHub Pages with hash routing

### Application Structure

This is a **public procurement management system** ("Comprar Bem") designed for Brazilian government agencies to manage:
- Product pre-qualification and standardization (DCB - Declaração de Conformidade de Bem)
- Electronic catalog of standardized products
- Market research and price reference
- Administrative processes and document management
- Post-purchase performance evaluation (RDM - Relatório de Desempenho de Material)

### Key Application Modules

#### Core Business Components
- **Dashboard**: Main control panel with metrics and alerts
- **DCB Management**: Product qualification and certification workflow
- **Catalog**: Electronic catalog of pre-qualified products
- **Analysis**: Product evaluation and approval processes
- **Feedback/RDM**: Post-purchase performance reporting system
- **Classification**: Product categorization management
- **Technical Research**: AI-powered search functionality

#### Authentication & Multi-tenancy
- Supabase-based authentication with tenant isolation
- Route guards protecting authenticated areas
- User session management in Vuex store

#### AI Integration
- **Gemini Service**: Robust fallback system across multiple Gemini models (2.0 Flash → 1.5 Flash → 1.5 Pro → 1.0 Pro)
- **QualiBot 2.0**: AI assistant specialized in public procurement
- Comprehensive retry logic with exponential backoff

### Database Architecture
- Multi-tenant architecture with tenant-based data isolation
- RLS (Row Level Security) policies for data access control
- Complex relationships between products, evaluations, and administrative processes

### File Structure Patterns
- **Views**: Main page components in `src/views/`
- **Components**: Reusable components organized by module in `src/components/`
- **Services**: API integrations and business logic in `src/services/`
- **Router**: Centralized routing with authentication guards
- **Store**: Vuex state management for user/tenant data

### API Integrations
- **Supabase**: Primary database and authentication
- **Google Gemini**: AI chat functionality with sophisticated fallback
- **EmailJS**: Email service integration
- **CNPJ Services**: Brazilian company validation

### Development Notes

#### Environment Configuration
- Production deploys to GitHub Pages with base path `/ComprarBem/`
- Hash routing used in production for GitHub Pages compatibility
- Lint on save disabled to prevent build interruptions

#### Multi-tenant Considerations
- All database queries must include tenant filtering
- User metadata contains `tenant_id` for data isolation
- Components should use `getTenantId()` helper when needed

#### Error Handling
- Gemini service implements comprehensive retry and fallback logic
- Authentication errors redirect to home page
- Network issues handled gracefully with user-friendly messages

#### Security
- Supabase anon key is public (intended for client-side use)
- RLS policies enforce data access control at database level
- Authentication required for most application routes

### Special Files
- **SQL Files**: Database setup and migration scripts in root directory
- **Documentation**: Extensive project documentation in `DOCUMENTOS ESCRITOS/`
- **Worker**: Service worker configuration for PWA features