// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// Project GitHub Pages: https://nikomix.github.io/microhack-avd
// `site` is the Pages origin; `base` is the repository sub-path.
// https://astro.build/config
export default defineConfig({
  site: 'https://nikomix.github.io',
  base: '/microhack-avd',
  integrations: [
    starlight({
      title: 'AVD Module B MicroHack',
      tagline: 'The Agentic Engagement — deliver every AVD Advanced Specialization Module B control with GitHub Copilot.',
      description:
        'A Train-the-Trainer MicroHack that teaches Microsoft partner consultants to deliver every Azure Virtual Desktop Advanced Specialization Module B control using GitHub Copilot custom agents, skills, and MCP servers — on real Azure, with Bicep and Terraform.',
      logo: {
        src: './src/assets/logo.svg',
        alt: 'AVD MicroHack',
      },
      favicon: '/favicon.svg',
      customCss: ['./src/styles/custom.css'],
      lastUpdated: true,
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/NikoMix/microhack-avd',
        },
      ],
      editLink: {
        baseUrl: 'https://github.com/NikoMix/microhack-avd/edit/main/docs/',
      },
      sidebar: [
        {
          label: 'Start here',
          items: [
            { label: 'Overview', link: '/' },
            { label: 'Scenario — Contoso', link: '/scenario/' },
            { label: 'The agentic toolkit', link: '/toolkit/' },
          ],
        },
        {
          label: 'Challenges (00–07)',
          items: [
            { label: 'All challenges', link: '/challenges/' },
            { label: '00 · Setup & guardrails', link: '/challenges/00-setup/' },
            { label: '01 · Workload assessment · B.1.1', link: '/challenges/01-workload-assessment/' },
            { label: '02 · Solution design (HLD) · B.2.1', link: '/challenges/02-solution-design/' },
            { label: '03 · Well-Architected review · B.2.2', link: '/challenges/03-well-architected-review/' },
            { label: '04 · PoC / Pilot · B.2.3', link: '/challenges/04-poc-pilot/' },
            { label: '05 · Deploy to production · B.3.1', link: '/challenges/05-deploy-to-production/' },
            { label: '06 · Service validation · B.4.1', link: '/challenges/06-service-validation/' },
            { label: '07 · Handover documentation · B.4.2', link: '/challenges/07-handover-documentation/' },
          ],
        },
        {
          label: 'Build & deliver',
          items: [
            { label: 'Infrastructure tracks', link: '/infra/' },
            { label: 'Facilitator kit', link: '/facilitator/' },
          ],
        },
      ],
    }),
  ],
});
