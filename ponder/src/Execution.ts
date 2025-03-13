// This file contains event handlers for Execution contract events
import { ponder } from "ponder:registry";

export function handleNewMovementCreated({ event, context }) {
  console.log("New Movement Created:", event.args);
}

export function handleQueueExecuted({ event, context }) {
  console.log("Queue Executed:", event.args);
}

export function handleNewSignaturesSubmitted({ event, context }) {
  console.log("New Signatures Submitted:", event.args);
}

export function handleSignatureRemoved({ event, context }) {
  console.log("Signature Removed:", event.args);
}

export function handleWillWeSet({ event, context }) {
  console.log("WillWe Set:", event.args);
}
