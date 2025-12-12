<script>
	import './layout.css';
	import favicon from '$lib/assets/favicon.svg';

	let { children } = $props();
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<title>Medication management that actually works</title>
	<meta name="description" content="Built by a nurse who gets it, ComplyHealth takes the mental load off medication management so you can focus on what matters - your health and your life." />
</svelte:head>

{@render children()}
