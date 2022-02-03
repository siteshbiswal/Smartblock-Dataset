// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ash Forest
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    .....''''''''''''''''''''''''''''''''''''''''''''''''''''''''''.................''''''''''''''''....''''''''''''''......    //
//    ....'''''''''''''''''''''''...'''....''''''''''''''''''''''''''...............''''''''''''''.........'''''''''''''......    //
//    '''''''''''''''''''''''''............'''',''''''''''''',,,,'''''..............'''''''''''..........'''.....''''''''....'    //
//    ''''''.......'''''''''''''...........'''',,,,,,''''''',;;;;;;;;,,'''''........''..'''''''........'''''......''''''''.'''    //
//    ''''.........'''''''''''''''........''''',,,,,,''''',,,:ccc::c::::;;:,',''..........''''''...........'......''''''''''''    //
//    '...........''''''''''''''''''....''''',,,,,,,,,,,,,,;::cllcllcccccclc:;;,''''''.'''''''''''''...............'''''''''''    //
//    ..........'''''''''''''''''''''''''',,,,,;;;;;;,,,;;,;:ccccllllllc::ll:;;;,,,,,''''''',,,,,''''''............'''''''''''    //
//    ..........''''''''''''''''''''''''''',,;;;;;:c:;;:::;;:clccloodolllllc:;;;;;::;,'''''''''''''''''''''........'''''''''''    //
//    ''.......''''''''''''......''..'''',,,,,,,,::looodddxdoooloodxxdolloollcccccccc;;,,'''''''''''''''''''''....''''''''''''    //
//    '''.......'''''............''.''',;::ccllcllodxxkOOOkkxxxddxxxxdoolodolclooolcc:::;,''''''''''''''''''''''''''''''''''''    //
//    ''........''........''....'''',,;codxxkOkxkkOkkkkOOOOOOkkkkxdddddooollccclooolccccc::;;,''''''''''''''''''''''''''''''''    //
//    .....................'''.'',;:cloxkkOO0K00000OkkOOkkOOO0OOkxdddoc::cccc:clclllcclllccc:;,'''''''''''''''''''''''''''''''    //
//    ........................',;clodxk00OOO0KK00000OkxdxkOxxOxxxxxxo:;;::clccolclollloooolc:;,''''''''''.........''''''''''''    //
//    ......................'',:llodxxxOOOO00XKkdxxxkxdloxkxddddxocclc;:lc:llccccloooddooooc:;;,''''''''..............''''''''    //
//    .......''.'''....''...'',:lodxkkOOOO000KKkoooldxoccol:dkddo:;;;clcc::llc:clloooddololcccc:;,'''''''..............''''''.    //
//    ....''''''''''''''''''',:ldxxxxxxxk0Okk000Oxoloxdoodlcdkdoc,,,,:lc;;:loolcc:coolccc::clodolc;,''''''.....'''......''''..    //
//    ..'''''''''''''''''''',:lddxkOkxdodkkxdxOxxxxdllooxxl:oddl,''',:cc:colcclc;:clc;;clccoodxdddl:,,,,''''''.'''''..........    //
//    ''''''''''''''''''''',;:lodkO00OkxdoxkddkOkkkxoc,,locooldo;''',loccc;,,,;:clolc::codoolodxoolc;,,,,,''''..'''''.........    //
//    ''''''''''''''''''.',;:clodxkO0OkxoodxdolcloxkOxc:c;'cc;cd:'',cdlcc:;;;:;;,;cl:;:locc:::llccc:;,,,,,''..'...''''''......    //
//    ''......''''''''....',;:cccodxxkkddxxdllc:,.,oxkxxo:,;c;'oxoool:;,',,;;;,,'';ccccc;,,;;;cccccc:;,,,,''..................    //
//    ...............'....'',;;;;:loddxxdoc;::clolloddkxc;::oololx0o'.....''''',,,;clcc;,,,;;:c:;;;c:,',,,,''.....''''.......'    //
//    .....................'',,;:looollllc;,,;;;;::coxxkd;'';xOl,lOl'.......''''',:l:;c;,;:c:::;;:;::;,,;;,,''..''''''''.....'    //
//    .....''..............''',;:cccllc:;,;;;'......';lxOxc:cololdOo'.......''''.'cc,:lcccccccccccccc::;::cc;'''''''''''''....    //
//    .....''.............''''',,;:col:;;;:;..........':xxldkc;:oOKx;''''''''''',clllolccc:::::::clllllccllc;,'...''''''''....    //
//    .....''...........''''''.'',;:c::;,,;,'.......'''',ddoko:::dO0xc;,'''''';coollol:;,,,;;::cccccloollcc:,''..''''''''.....    //
//    ....''''.........''''''....',;::;,,,'''''''....'''',ok0d:lc:cxOl:;,'';codoc:::::ccccc:;;;;::ccloollc:;'.................    //
//    ....'''''.......''''''''....'',;,''''','''.........',oK0occ:;cOOlcloddo:,,',,,,,;;:c:::;;;:llllllll:;'..................    //
//    ....''''''.......'''''..............'''''''..........'lKk;;:clkK0kkdc;'''',,,;,,,;,,'';;,,;clcclol:,''..................    //
//    .....''''''............''...............''''.........';x0l,;;:kXOoc:;;,'''',,,,,'''...',',,:lcccc:;,'...................    //
//    ......'''''............''.................'..........',;kOc;:l0Oc;;;,,'''''''''''.....,,',;:cccc;,''.........''''.......    //
//    ......''''''...........................'''..............:Ox:ck0:..'''''''''''''''..''';;,,;:;;,''............''''.......    //
//    ......''''''''...........................................l0000l''''''''''''.....'..'',,,,''',,'..............''''.......    //
//    ....''''''''''''.........................................,kWWk,''''',,'''''......''''''''''''..........''....''''.......    //
//    ''''''''''''''''.......................................'',xNNx,''''''''''''......''''''...............''''.....''.......    //
//    ''''''''''....''..................'''................'''',xNNx,'...'''''''''......'''..................'''..............    //
//    '''.'''''......'................''''''...............'''',xNNx,'....''''''''............................................    //
//    .''''''''.....................''''''''..............''''',xNNx,'.......'...'...............'...'..''''..................    //
//    '................'...........'''''''''..........''''''',',xNNx,'..'.......................'''...........................    //
//    'ashforest,.......'.........''''''''''''''''''''',,,,,,,',xNNx,'..'''...................................................    //
//    .'''','''''''''''''''''..'''''''''''''''''''''',,,,,,,,'',xNNx,'''.'''..................................................    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AF is ERC721Creator {
    constructor() ERC721Creator("Ash Forest", "AF") {}
}