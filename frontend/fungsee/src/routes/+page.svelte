
<script>
        import { lineaTestnet } from "@wagmi/core/chains";
        import {
        wagmiLoaded,
        connected,
        web3Modal,
        defaultConfig,
        signerAddress,
        connection,
        chainId,
    } from "svelte-wagmi";


    import { baseGoerli } from "@wagmi/core/chains";

    import { FUNADDRESS, FunABI } from "../lib/ABIs.js";

    import { ethers } from "ethers";
    import { onMount } from "svelte";


    onMount(async () => {




        let account = $signerAddress;
        if (account) {
            fetch(`/onchain/?useraddress=${account}`)
                .then((res) => res.json())
                .then((d) => {
                    console.log(d);
                }
                );

    };

});
</script>


<div class="row">


</div>