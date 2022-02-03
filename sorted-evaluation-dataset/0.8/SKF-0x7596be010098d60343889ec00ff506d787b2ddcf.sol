// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Skife
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╣╣╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠╠╠╠╬╝╝╝╝╝╝╝╝╝╝╝╝╣╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠╠╠╠╠ ▒▒▒▒▒▒▒▒▒▓⌐╟╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠╠╠╠/ ,╓╓╓╓/////_╚╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠╠╠╩_H'╬╬╬╬╬╬╬╬╬▓_╟▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠╠╩_╠╬┐╙╬╬╬╬╬╬╬╬╣▓_╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠/_╠╬╬╬_║╬╬╬╬╬╬╬╣╣▓_╫▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠ ,,,,,_   SKIFE   ▒╙╙╙╙▓▓▓▓▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠ ╠╠╬╬╬╠ ╬╬╣╙╫╣╜╙╫╣▌ ╣▓▓▓▓▓ ▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠ ╠╠╬╬╬╠ ╬╬⌐║╬`║▌ ╣▌ ╣▓▓▓▓▓ ▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠ ╠╠╬╬╬╠ ╬╬▒╓╓╗╣▄╣╣▌ ╣▓▓▓▓▓ ▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠ ╠╠╬╬╬╠ ╬╬▒/Γ`//╠╣▌ ╣▓▓▓▓▓ ▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠ ╠╠╬╬╬╠ ╬╬╬╣╝^_╙╣╣▌ ╣▓▓▓▓▓ ▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠ ╠╠╬╬╬╠ ╬╬▒╔@╣╣▓▄╣▌ ╣▓▓▓▓▓ ▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠ ╠╠╬╬╬╠ ╬╬▒╓╓╓╓╓/╣▌ ╣▓▓▓▓▓ ▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠ ╠╠╬╬╬╠ ╬╬▒╙╙╙╙╙╙╣▌ ╣▓▓▓▓▓ ▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠ ╠╠╬╬╬╠ ╬╬╬╬╬ ╣╬'╣▌ ╣▓▓▓▓▓ ▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠ ╠╠╬╬╬╠ ╬╬╬╬╬▒╣╬▄╣▌ ╣▓▓▓▓▓ ▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠ ╠╠╬╬╬╠ ╬╬/╓▄ ╔╥'╣▌ ╣▓▓▓▓▓ ▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠ ╠╠╬╬╬╠ ╬╬/║╬,╫╬'╣▌ ╣▓▓▓▓▓ ▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠ ╠╠╠╟╬╠ ╬╣╣╣╣╣╣╣╣╣▌ ╣▓▓▓▓▓ ▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠╗╦╗φφφφ_jφφφφφφφφ▄▄⌐╔▄▄▄▄⌐╔▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠╠╠╠╬╬╬╬╬_╟╬╬╬╬╬╣╣╣▓▓ ▓▓▓Ñ╔▓▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠╠╠╠╬╬╬╬╬╬ ╣╬╬╬╬╣╣╣▓▓▒└▓Ñ╔▓▓▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠╠╠╠╬╬╬╬╬╬▒ ╣╣╣╣╣╣╣╣▓▓╕"╔▓▓▓▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠╠╠╠╬╬╬╬╬╬╬▒╒φφφφφφ▄▄▄▄ ▓▓▓▓▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠╠╠╠╬╬╬╬╬╬╬▒'╙╙╙╙╙╙╙╙╙╙_▓▓▓▓▓▓▓▓▓▓████████████████████    //
//          ¬¬┌┌»»»»░░░░░h]ÜÜÜ▒▒▒▒╠╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╣╣╣▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████████████    //
//          ````````````````````````````""""""""""""""""""""╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙    //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract SKF is ERC721Creator {
    constructor() ERC721Creator("Skife", "SKF") {}
}