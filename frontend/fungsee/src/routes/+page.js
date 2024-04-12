import { error } from '@sveltejs/kit';
import { ethers } from 'ethers';
import { FUNADDRESS, FunABI } from '$lib/ABIs';
import { chainId } from 'ethers-svelte';
import { onMount } from 'svelte';
 
/** @type {import('./$types').PageLoad} */
export function load({ params }) {

 console.log("params: ", params)


}