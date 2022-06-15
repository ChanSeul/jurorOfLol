//
//  Transform.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/01.
//

import Foundation

public struct Transform: Encodable {
    let collectionId: String
    let documentId: String
    let updateVote: voteUpdateType?
    let post: Post?
    
    // vote1, vote2, totalVotes 업데이트할 때
    public init(_ collectionId: String, _ documentId: String, _ updateVote: voteUpdateType) {
        self.collectionId = collectionId
        self.documentId = documentId
        self.updateVote = updateVote
        self.post = nil
    }
    
    // url, champion1, champion2, text 업데이트할 때
    public init(_ collectionId: String, _ post: Post) {
        self.collectionId = collectionId
        self.documentId = post.docID
        self.updateVote = nil
        self.post = post
    }
    
    private enum CodingKeys: String, CodingKey {
        case writes
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let updateVote = updateVote { // vote1, vote2, totalVotes 업데이트할 때
            try container.encode([Writes(collectionId, documentId, updateVote)], forKey: .writes)
        } else if let post = post { // url, champion1, champion2, text 업데이트할 때
            try container.encode([Writes(collectionId, post)], forKey: .writes)
        }
    }
}
extension Transform {
    public struct Writes: Encodable {
        let collectionId: String
        let documentId: String
        let updateVote: voteUpdateType?
        let post: Post?
        
        public init(_ collectionId: String, _ documentId: String, _ updateVote: voteUpdateType) {
            self.collectionId = collectionId
            self.documentId = documentId
            self.updateVote = updateVote
            self.post = nil
        }
        
        public init(_ collectionId: String, _ post: Post) {
            self.collectionId = collectionId
            self.documentId = post.docID
            self.updateVote = nil
            self.post = post
        }
        
        private enum WritesKeys: String, CodingKey {
            case currentDocument
            case transform
            case updateMask
            case update
        }
        private enum CurrentDocumentKeys: String, CodingKey {
            case exists
        }
        private enum TransformKeys: String, CodingKey {
            case document
            case fieldTransforms
        }
        private enum UpdateMaskKeys: String, CodingKey {
            case fieldPaths
        }
        private enum UpdateKeys: String, CodingKey {
            case name
            case fields
        }
        private enum FieldsKeys: String, CodingKey {
            case url
            case champion1
            case champion2
            case text
        }
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: WritesKeys.self)
            var currentDocumentContainer = container.nestedContainer(keyedBy: CurrentDocumentKeys.self, forKey: .currentDocument)
            try currentDocumentContainer.encode(true, forKey: .exists)
            
            
            if let updateVote = updateVote {
                var transformContainer = container.nestedContainer(keyedBy: TransformKeys.self, forKey: .transform)
                try transformContainer.encode("projects/lolcourt-554c8/databases/(default)/documents/\(collectionId)/\(documentId)", forKey: .document)
                
                switch updateVote {
                case .onlyAddFirst:
                    try transformContainer.encode([FieldTransforms(.incrementVote1), FieldTransforms(.incrementTotal)], forKey: .fieldTransforms)
                case .onlyDecreaseFirst:
                    try transformContainer.encode([FieldTransforms(.decreaseVote1), FieldTransforms(.decreseTotal)], forKey: .fieldTransforms)
                case .onlyAddSecond:
                    try transformContainer.encode([FieldTransforms(.incrementVote2), FieldTransforms(.incrementTotal)], forKey: .fieldTransforms)
                case .onlyDecreaseSecond:
                    try transformContainer.encode([FieldTransforms(.decreaseVote2), FieldTransforms(.decreseTotal)], forKey: .fieldTransforms)
                case .addFirstDecreaseSecond:
                    try transformContainer.encode([FieldTransforms(.incrementVote1), FieldTransforms(.decreaseVote2)], forKey: .fieldTransforms)
                case .decreaseFirstAddSecond:
                    try transformContainer.encode([FieldTransforms(.decreaseVote1), FieldTransforms(.incrementVote2)], forKey: .fieldTransforms)
                }
            } else if let post = post {
                var updateMaskContainer = container.nestedContainer(keyedBy: UpdateMaskKeys.self, forKey: .updateMask)
                try updateMaskContainer.encode(["url", "champion1", "champion2", "text"], forKey: .fieldPaths)
                var updateContainer = container.nestedContainer(keyedBy: UpdateKeys.self, forKey: .update)
                try updateContainer.encode("projects/lolcourt-554c8/databases/(default)/documents/\(collectionId)/\(documentId)", forKey: .name)
                var fieldsContainer = updateContainer.nestedContainer(keyedBy: FieldsKeys.self, forKey: .fields)
                try fieldsContainer.encode(StringValue(value: post.url), forKey: .url)
                try fieldsContainer.encode(StringValue(value: post.champion1), forKey: .champion1)
                try fieldsContainer.encode(StringValue(value: post.champion2), forKey: .champion2)
                try fieldsContainer.encode(StringValue(value: post.text), forKey: .text)
            }
            
        }
    }
    
    public struct FieldTransforms: Encodable {
        let updateType: TransformType
        
        public init(_ updateType: TransformType) {
            self.updateType = updateType
        }
        
        public enum TransformType: String {
            case incrementVote1
            case incrementVote2
            case decreaseVote1
            case decreaseVote2
            case incrementTotal
            case decreseTotal
        }
        
        private enum FieldTransformsKeys: String, CodingKey {
            case fieldPath
            case increment
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: FieldTransformsKeys.self)
            
            switch updateType {
            case .incrementVote1:
                try container.encode("vote1", forKey: .fieldPath)
                try container.encode(IntegerValue(value: "1"), forKey: .increment)
            case .incrementVote2:
                try container.encode("vote2", forKey: .fieldPath)
                try container.encode(IntegerValue(value: "1"), forKey: .increment)
            case .decreaseVote1:
                try container.encode("vote1", forKey: .fieldPath)
                try container.encode(IntegerValue(value: "-1"), forKey: .increment)
            case .decreaseVote2:
                try container.encode("vote2", forKey: .fieldPath)
                try container.encode(IntegerValue(value: "-1"), forKey: .increment)
            case .incrementTotal:
                try container.encode("totalVotes", forKey: .fieldPath)
                try container.encode(IntegerValue(value: "1"), forKey: .increment)
            case .decreseTotal:
                try container.encode("totalVotes", forKey: .fieldPath)
                try container.encode(IntegerValue(value: "-1"), forKey: .increment)
            }
        }
    }
}




