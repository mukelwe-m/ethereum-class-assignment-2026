"use client";

import Link from "next/link";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { BugAntIcon, MagnifyingGlassIcon, ClipboardDocumentListIcon } from "@heroicons/react/24/outline";
import { Address } from "~~/components/scaffold-eth";
import { useTargetNetwork } from "~~/hooks/scaffold-eth";

const Home: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const { targetNetwork } = useTargetNetwork();

  return (
    <>
      <div className="flex items-center flex-col grow pt-10">
        <div className="px-5 text-center">
          <h1>
            <span className="block text-2xl mb-2">DeFi Exchange Dashboard</span>
            <span className="block text-4xl font-bold text-primary">PNP vs FNB Order Book</span>
          </h1>

          <div className="flex justify-center items-center space-x-2 flex-col my-6 bg-base-200 p-4 rounded-xl">
            <p className="font-medium m-0 mb-1">Active Trader Session:</p>
            <Address address={connectedAddress} />
          </div>
        </div>

        <div className="grow bg-base-300 w-full mt-10 px-8 py-12">
          <div className="flex justify-center items-center gap-8 flex-col md:flex-row max-w-4xl mx-auto">
            
            {/* Debug Link */}
            <div className="flex flex-col bg-base-100 px-6 py-8 text-center items-center flex-1 rounded-3xl shadow-md min-h-[180px]">
              <BugAntIcon className="h-8 w-8 text-primary mb-2" />
              <p className="font-semibold text-lg m-0">Interact</p>
              <p className="text-sm mt-1">
                Place orders and invoke functions via the{" "}
                <Link href="/debug" passHref className="link font-bold">
                  Debug Contracts
                </Link>{" "}
                portal.
              </p>
            </div>

            {/* Block Explorer Link */}
            <div className="flex flex-col bg-base-100 px-6 py-8 text-center items-center flex-1 rounded-3xl shadow-md min-h-[180px]">
              <MagnifyingGlassIcon className="h-8 w-8 text-primary mb-2" />
              <p className="font-semibold text-lg m-0">Ledger</p>
              <p className="text-sm mt-1">
                Audit local state changes using the internal{" "}
                <Link href="/blockexplorer" passHref className="link font-bold">
                  Block Explorer
                </Link>.
              </p>
            </div>

          </div>
        </div>
      </div>
    </>
  );
};

export default Home;