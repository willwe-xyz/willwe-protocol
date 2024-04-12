<script>
    import {
        wagmiLoaded,
        connected,
        web3Modal,
        defaultConfig,
        signerAddress,
        connection,
        chainId,
    } from "svelte-wagmi";

    import { onMount } from "svelte";
    import Icon from "$lib/assets/logo250.gif";
    import { lineaTestnet } from "@wagmi/core/chains";
    import { ethers } from "ethers";

    let currentSignature;
    let currentMessage;
    let currentUserAddress;

    onMount(async () => {
        // @ts-ignore
        const config = defaultConfig({
            appName: "Fungsee",
            appIcon: Icon,
            autoConnect: true,
            walletConnectProjectId: "d80fa2161e09201d0bd5eb0eb0b9674c",
        });

        await config.init();
    });

    const chageLoginBtnText = () => {
        const btn = document.getElementById("loginBtn");
        btn.innerHTML == "generic"
            ? (btn.innerHTML = "authentic")
            : (btn.innerHTML = "generic");
    };
</script>

<hr class="topline-root" />
<p class="signer-top">
    {$signerAddress
        ? $signerAddress
        : "0x0000000000000000000000000000000000000000"} 
    {$chainId==59140 ? "@goerli.linea.eth"  : `${$chainId}` }
</p>
<div class="container container-head">
    <div class="row">
        <div class="col-5" />
        <div class="col-2">
            <img src={Icon} class="fungi-logo" alt="logo" width="30.6%" />
        </div>
        <div class="col-5-md">
            <div class="row">
                <span class="log-in-button">
                    {#if $web3Modal}
                        <button
                            id="loginBtn"
                            on:click={() => $web3Modal.openModal()}
                            class="btn btn-outline-info float-end purple dark-border dotted light-hover bold loginBtn"
                            on:mouseenter={() => {
                                chageLoginBtnText();
                            }}
                            on:mouseleave={() => {
                                chageLoginBtnText();
                            }}
                            >{$signerAddress ? "authentic" : "generic"}</button
                        >
                    {:else}
                        "...loading"
                    {/if}
                </span>
            </div>
        </div>
    </div>
</div>
<br>
<div class="body">
    {#if $signerAddress}
        <div class="container bodycontainer">
            <slot />
        </div>
    {:else}
        <div class="container">
            <div class="row">
                <div class="col-12">
                    <h2 class="text-center">Generic Experience</h2>
                    <h3 class="text-center black">batteries not included</h3>
                </div>
                <br />
                <br />
                <br />
                <p>
                    There's nothing wrong with being a robot as long as you
                    bring your hole self to work
                </p>
                <p class="black">
                    That said this space requires one to bring something unique
                </p>
                <p>To make the best of it, mirror it</p>
                <p class="black">Here's a tip: nothing without energy</p>
                <p>Here's another tip: nothing without an identifier</p>
                <p class="black">
                    Here's another tip: without a beginning or an end,
                    everything
                </p>
                <p>But nothing in particular without a membrane</p>
                <p class="black">
                    But nothing predictable without determination
                </p>
            </div>
        </div>
    {/if}
    <div class="footer">

            <div class="row">
                <p class="footer black">
                    Made with ❤️ by <a href="http://github.com/parseb">parseb</a
                    >
                </p>
            </div>

    </div>

</div>

<style>
    .footer a {
        text-decoration: none;
        color: #badad5;
    }

    footer a:hover {
        text-decoration: underline;
    }

    .footer {
        bottom: 2px;
        position: absolute;
        text-align: center;
        margin-top: 10px;
        font-size: 10px;
        width: 100%;
        color: #888;
    }

    .btn.loginBtn {
        display: inline-block;

        width: 90px;
    }
    .container-head {
        margin-top: -6px;
    }

    .bold {
        font-weight: bold;
    }
    .dark-border {
        border-color: #212936;
    }

    .dotted {
        border-style: none;
    }

    .light-hover:hover {
        background: linear-gradient(45deg, #4fab, #9f6);
        color: #5b89be;
        border-color: #badad5;
    }
    .blue {
        color: #5b89be;
    }
    .gren {
        color: #4faba6;
    }

    .white {
        color: #badad5;
    }
    .red {
        color: #e24b3f;
    }

    .purple {
        color: #5f478a;
    }

    .black {
        color: #212936;
    }

    .fungi-logo {
        top: 1px;
        position: absolute;
        height: 65px;
        width: 65px;
    }
    .topline-root {
        height: 8px;
        color: #ffffff;
        opacity: 0.9;

        position: relative;
        margin-top: -1px;
    }

    .signer-top {
        opacity: 0.12;
        font-size: 36px;
        position: absolute;
        margin-top: -36px;
        overflow: hidden;
    }
</style>
