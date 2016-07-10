import Foundation
import Parse

final class PAPCache {
    private var cache: Cache<AnyObject, AnyObject>

    // MARK:- Initialization
    
    static let sharedCache = PAPCache()

    private init() {
        self.cache = Cache()
    }

    // MARK:- PAPCache

    func clear() {
        cache.removeAllObjects()
    }

    func setAttributesForPhoto(photo: PFObject, likers: [PFUser], commenters: [PFUser], likedByCurrentUser: Bool) {
        let attributes = [
            kPAPPhotoAttributesIsLikedByCurrentUserKey: likedByCurrentUser,
            kPAPPhotoAttributesLikeCountKey: likers.count,
            kPAPPhotoAttributesLikersKey: likers,
            kPAPPhotoAttributesCommentCountKey: commenters.count,
            kPAPPhotoAttributesCommentersKey: commenters
        ]
        setAttributes(attributes: attributes as! [String : AnyObject], forPhoto: photo)
    }

    func attributesForPhoto(photo: PFObject) -> [String:AnyObject]? {
        let key: String = self.keyForPhoto(photo: photo)
        return cache.object(forKey: key) as? [String:AnyObject]
    }

    func likeCountForPhoto(photo: PFObject) -> Int {
        let attributes: [NSObject:AnyObject]? = self.attributesForPhoto(photo: photo)
        if attributes != nil {
            return attributes![kPAPPhotoAttributesLikeCountKey] as! Int
        }

        return 0
    }

    func commentCountForPhoto(photo: PFObject) -> Int {
        let attributes = attributesForPhoto(photo: photo)
        if attributes != nil {
            return attributes![kPAPPhotoAttributesCommentCountKey] as! Int
        }
        
        return 0
    }

    func likersForPhoto(photo: PFObject) -> [PFUser] {
        let attributes = attributesForPhoto(photo: photo)
        if attributes != nil {
            return attributes![kPAPPhotoAttributesLikersKey] as! [PFUser]
        }
        
        return [PFUser]()
    }

    func commentersForPhoto(photo: PFObject) -> [PFUser] {
        let attributes = attributesForPhoto(photo: photo)
        if attributes != nil {
            return attributes![kPAPPhotoAttributesCommentersKey] as! [PFUser]
        }
        
        return [PFUser]()
    }

    func setPhotoIsLikedByCurrentUser(photo: PFObject, liked: Bool) {
        var attributes = attributesForPhoto(photo: photo)
        attributes![kPAPPhotoAttributesIsLikedByCurrentUserKey] = liked
        setAttributes(attributes: attributes!, forPhoto: photo)
    }

    func isPhotoLikedByCurrentUser(photo: PFObject) -> Bool {
        let attributes = attributesForPhoto(photo: photo)
        if attributes != nil {
            return attributes![kPAPPhotoAttributesIsLikedByCurrentUserKey] as! Bool
        }
        
        return false
    }

    func incrementLikerCountForPhoto(photo: PFObject) {
        let likerCount = likeCountForPhoto(photo: photo) + 1
        var attributes = attributesForPhoto(photo: photo)
        attributes![kPAPPhotoAttributesLikeCountKey] = likerCount
        setAttributes(attributes: attributes!, forPhoto: photo)
    }

    func decrementLikerCountForPhoto(photo: PFObject) {
        let likerCount = likeCountForPhoto(photo: photo) - 1
        if likerCount < 0 {
            return
        }
        var attributes = attributesForPhoto(photo: photo)
        attributes![kPAPPhotoAttributesLikeCountKey] = likerCount
        setAttributes(attributes: attributes!, forPhoto: photo)
    }

    func incrementCommentCountForPhoto(photo: PFObject) {
        let commentCount = commentCountForPhoto(photo: photo) + 1
        var attributes = attributesForPhoto(photo: photo)
        attributes![kPAPPhotoAttributesCommentCountKey] = commentCount
        setAttributes(attributes: attributes!, forPhoto: photo)
    }

    func decrementCommentCountForPhoto(photo: PFObject) {
        let commentCount = commentCountForPhoto(photo: photo) - 1
        if commentCount < 0 {
            return
        }
        var attributes = attributesForPhoto(photo: photo)
        attributes![kPAPPhotoAttributesCommentCountKey] = commentCount
        setAttributes(attributes: attributes!, forPhoto: photo)
    }

    func setAttributesForUser(user: PFUser, photoCount count: Int, followedByCurrentUser following: Bool) {
        let attributes = [
            kPAPUserAttributesPhotoCountKey: count,
            kPAPUserAttributesIsFollowedByCurrentUserKey: following
        ]

        setAttributes(attributes: attributes as! [String : AnyObject], forUser: user)
    }

    func attributesForUser(user: PFUser) -> [String:AnyObject]? {
        let key = keyForUser(user: user)
        return cache.object(forKey: key) as? [String:AnyObject]
    }

    func photoCountForUser(user: PFUser) -> Int {
        if let attributes = attributesForUser(user: user) {
            if let photoCount = attributes[kPAPUserAttributesPhotoCountKey] as? Int {
                return photoCount
            }
        }
        
        return 0
    }

    func followStatusForUser(user: PFUser) -> Bool {
        if let attributes = attributesForUser(user: user) {
            if let followStatus = attributes[kPAPUserAttributesIsFollowedByCurrentUserKey] as? Bool {
                return followStatus
            }
        }

        return false
    }

    func setPhotoCount(count: Int,  user: PFUser) {
        if var attributes = attributesForUser(user: user) {
            attributes[kPAPUserAttributesPhotoCountKey] = count
            setAttributes(attributes: attributes, forUser: user)
        }
    }

    func setFollowStatus(following: Bool, user: PFUser) {
        if var attributes = attributesForUser(user: user) {
            attributes[kPAPUserAttributesIsFollowedByCurrentUserKey] = following
            setAttributes(attributes: attributes, forUser: user)
        }
    }

    func setFacebookFriends(friends: NSArray) {
        let key: String = kPAPUserDefaultsCacheFacebookFriendsKey
        self.cache.setObject(friends, forKey: key)
        UserDefaults.standard().set(friends, forKey: key)
        UserDefaults.standard().synchronize()
    }

    func facebookFriends() -> [PFUser] {
        let key = kPAPUserDefaultsCacheFacebookFriendsKey
        if cache.object(forKey: key) != nil {
            return cache.object(forKey: key) as! [PFUser]
        }
        
        let friends = UserDefaults.standard().object(forKey: key)
        if friends != nil {
            cache.setObject(friends!, forKey: key)
            return friends as! [PFUser]
        }
        return [PFUser]()
    }

    // MARK:- ()

    func setAttributes(attributes: [String:AnyObject], forPhoto photo: PFObject) {
        let key: String = self.keyForPhoto(photo: photo)
        cache.setObject(attributes, forKey: key)
    }

    func setAttributes(attributes: [String:AnyObject], forUser user: PFUser) {
        let key: String = self.keyForUser(user: user)
        cache.setObject(attributes, forKey: key)
    }

    func keyForPhoto(photo: PFObject) -> String {
        return "photo_\(photo.objectId)"
    }

    func keyForUser(user: PFUser) -> String {
        return "user_\(user.objectId)"
    }
}
