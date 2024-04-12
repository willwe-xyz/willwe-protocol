import {ethers} from 'ethers';
import { json } from '@sveltejs/kit';
import { error } from '@sveltejs/kit';


import {
    connected,
    provider,
    chainId,
    defaultEvmStores,
    signer,
    signerAddress,
    contracts,
  } from "ethers-svelte"


import { SECRET_VERY_PRIVATE_KEY } from '$env/static/private';
import {PUBLIC_FUNGIDO_ADDRESS} from '$env/static/public';
import {FunABI} from '../../lib/ABIs';

// import { Client } from "@covalenthq/client-sdk";

// const getTokensAndMembershipsOfUser = async () => {
//     const client = new Client(`${SECRET_COVALENT_KEY}`);
//     const resp = await client.BalanceService.checkOwnershipInNft("base-testnet", {});
//     console.log(resp.data);
// }


// const headers = new Headers();
// headers.set('Authorization', `Bearer ${SECRET_COVALENT_KEY}`);


  const readProvider = new ethers.JsonRpcProvider("https://goerli.base.org");
  const rootWallet = new ethers.Wallet(SECRET_VERY_PRIVATE_KEY);
  const fungidoContract = new ethers.Contract(PUBLIC_FUNGIDO_ADDRESS, FunABI, readProvider);

const getAllUserData = async (/** @type {String} */ user) => {
  let userFunData =  await fungidoContract.getUserInteractions( user )
  .then( (data) => {
    console.log("data: ", data);
    return data;
  })


}
 


export async function GET({ request , url}) {
  // Handle the GET request
  console.log("params: ", url);
const u =  url.searchParams.get("useraddress");
  const data = {

    user: u,
    timestamp: new Date().toISOString(),
    data: await getAllUserData(u)
  };

  // Return data for server-side rendering
  return  new Response(JSON.stringify(data), {status: 200, headers: {'Content-Type': 'application/json'}}  );
}




    // export async function get(req, res, next) {
    //     const { slug } = req.params;
    //     const { page } = req.query;
    //     const { contract } = req.query;

    //     console.log("slug: ", slug);


    //     return res.json({ slug });
    // }

    