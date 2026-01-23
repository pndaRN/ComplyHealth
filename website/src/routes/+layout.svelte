<script>
	import './layout.css';
	import favicon from '$lib/assets/favicon.svg';
	import { isDark } from '$lib/stores/theme.js';

	let { children } = $props();
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<title>Medication management that actually works</title>
	<meta name="description" content="Built by healthcare professionals who get it, ComplyHealth takes the mental load off medication management so you can focus on what matters - your health and your life." />
	<meta name="color-scheme" content="light dark" />
	<meta name="theme-color" content={$isDark ? '#0F172A' : '#FFFFFF'} />
</svelte:head>

<div class={$isDark ? 'dark' : ''}>
	{@render children()}
</div>
