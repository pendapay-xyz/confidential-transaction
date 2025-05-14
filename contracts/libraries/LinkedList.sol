// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title LinkedList Library
/// @notice Doubly linked list library for storing sequences of bytes32 identifiers (e.g., UTXO transaction IDs)
library LinkedList {
    struct Node {
        bytes32 prev;
        bytes32 next;
    }

    struct List {
        mapping(bytes32 => Node) nodes;
        bytes32 head;
        bytes32 tail;
        uint256 size;
    }

    /// @notice Check if the list is empty
    function isEmpty(List storage list) internal view returns (bool) {
        return list.size == 0;
    }

    /// @notice Return the number of elements in the list
    function length(List storage list) internal view returns (uint256) {
        return list.size;
    }

    /// @notice Check whether an ID exists in the list
    function contains(List storage list, bytes32 id) internal view returns (bool) {
        if (list.size == 0) return false;
        if (list.head == id || list.tail == id) return true;
        Node storage node = list.nodes[id];
        return node.prev != bytes32(0) || node.next != bytes32(0);
    }

    /// @notice Insert `id` at the front (head) of the list
    function pushFront(List storage list, bytes32 id) internal {
        require(id != bytes32(0), "LinkedList: id zero");
        require(!contains(list, id), "LinkedList: already in list");

        if (isEmpty(list)) {
            list.head = id;
            list.tail = id;
        } else {
            list.nodes[list.head].prev = id;
            list.nodes[id].next = list.head;
            list.head = id;
        }
        list.size++;
    }

    /// @notice Insert `id` at the back (tail) of the list
    function pushBack(List storage list, bytes32 id) internal {
        require(id != bytes32(0), "LinkedList: id zero");
        require(!contains(list, id), "LinkedList: already in list");

        if (isEmpty(list)) {
            list.head = id;
            list.tail = id;
        } else {
            list.nodes[list.tail].next = id;
            list.nodes[id].prev = list.tail;
            list.tail = id;
        }
        list.size++;
    }

    /// @notice Remove `id` from the list
    function remove(List storage list, bytes32 id) internal {
        require(contains(list, id), "LinkedList: id not in list");
        Node storage node = list.nodes[id];

        if (node.prev != bytes32(0)) {
            list.nodes[node.prev].next = node.next;
        } else {
            list.head = node.next;
        }

        if (node.next != bytes32(0)) {
            list.nodes[node.next].prev = node.prev;
        } else {
            list.tail = node.prev;
        }

        delete list.nodes[id];
        list.size--;
    }

    /// @notice Get the next ID after `id`
    function next(List storage list, bytes32 id) internal view returns (bytes32) {
        require(contains(list, id), "LinkedList: id not in list");
        return list.nodes[id].next;
    }

    /// @notice Get the previous ID before `id`
    function prev(List storage list, bytes32 id) internal view returns (bytes32) {
        require(contains(list, id), "LinkedList: id not in list");
        return list.nodes[id].prev;
    }

    /// @notice Traverse the list starting at `start` up to `count` items (or until tail) and return IDs
    /// @param list The linked list storage
    /// @param start The ID to begin traversal from
    /// @param maxCount Maximum number of nodes to traverse
    /// @return ids Array of traversed IDs (length <= maxCount)
    function traverse(List storage list, bytes32 start, uint256 maxCount) internal view returns (bytes32[] memory) {
        require(contains(list, start), "LinkedList: start not in list");

        // Determine actual number of nodes to traverse
        uint256 actualCount = 0;
        bytes32 current = start;
        while (actualCount < maxCount && current != bytes32(0)) {
            actualCount++;
            current = list.nodes[current].next;
        }

        // Populate array with traversed IDs
        bytes32[] memory ids = new bytes32[](actualCount);
        current = start;
        for (uint256 i = 0; i < actualCount; i++) {
            ids[i] = current;
            current = list.nodes[current].next;
        }

        return ids;
    }

    /// @notice Get the head ID of the list
    function getHead(List storage list) internal view returns (bytes32) {
        return list.head;
    }

    /// @notice Get the tail ID of the list
    function getTail(List storage list) internal view returns (bytes32) {
        return list.tail;
    }
}
